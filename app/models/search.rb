class Search
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::AttributeMethods
  extend ActiveModel::Naming

  attr_accessor :q, :order
  attr_accessor :results, :page, :total_results, :per_page
  attr_writer :what

  validates :q, length: { :minimum => 2 }

  def initialize
    @q = ""
    @what = "stories"
    @order = "relevance"

    @page = 1
    @per_page = 20

    @results = []
    @total_results = -1
  end

  def max_matches
    100
  end

  def persisted?
    false
  end

  def to_url_params
    [:q, :what, :order].map {|p| "#{p}=#{CGI.escape(self.send(p).to_s)}" }.join("&amp;")
  end

  def page_count
    total = self.total_results.to_i

    if total == -1 || total > self.max_matches
      total = self.max_matches
    end

    ((total - 1) / self.per_page.to_i) + 1
  end

  def what
    case @what
    when "comments"
      "comments"
    else
      "stories"
    end
  end

  def with_tags(base, tag_scopes)
    base
      .joins({ :taggings => :tag }, :user).left_outer_joins(:story_text)
      .where(:tags => { :tag => tag_scopes })
      .having("COUNT(stories.id) = ?", tag_scopes.length)
      .group("stories.id")
  end

  def with_stories_in_domain(base, domain)
    # Get around the fact that case uses === not ==
    # to compare objects
    case base.klass
    when ->(b) { b == Story }
      base.joins(:domain).left_outer_joins(:story_text)
    when ->(b) { b == Comment }
      base.joins(story: [:domain])
    else
      fail "Can't handle #{base.class}"
    end.where('domains.domain = ?', domain)
  end

  def with_stories_matching_tags(base, tag_scopes)
    story_ids_matching_tags = with_tags(
      Story.unmerged.where(:is_expired => false), tag_scopes
    ).select(:id).map(&:id)
    base.where(story_id: story_ids_matching_tags)
  end

  def search_for_user!(user)
    self.results = []
    self.total_results = 0

    # extract domain query since it must be done separately
    domain = nil
    tag_scopes = []
    words = self.q.to_s.split(" ").reject {|w|
      if (m = w.match(/^domain:(.+)$/))
        domain = m[1]
      elsif (m = w.match(/^tag:(.+)$/))
        tag_scopes << m[1]
      end
    }.join(" ")

    qwords = ActiveRecord::Base.connection.quote_string(words)

    base = nil

    case self.what
    when "stories"
      base = Story.unmerged.where(:is_expired => false)
      if domain.present?
        base = with_stories_in_domain(base, domain)
      end

      title_match_sql = Arel.sql("MATCH(stories.title) AGAINST('#{qwords}' IN BOOLEAN MODE)")
      description_match_sql =
        Arel.sql("MATCH(stories.description) AGAINST('#{qwords}' IN BOOLEAN MODE)")
      story_text_match_sql =
        Arel.sql("MATCH(story_texts.body) AGAINST('#{qwords}' IN BOOLEAN MODE)")

      if qwords.present?
        base.where!(
          "(#{title_match_sql} OR " +
          "#{description_match_sql} OR " +
          "#{story_text_match_sql})"
        )

        if tag_scopes.present?
          self.results = with_tags(base, tag_scopes)
        else
          base = base.includes({ :taggings => :tag }, :user).left_outer_joins(:story_text)
          self.results = base.select(
            ["stories.*", title_match_sql, description_match_sql, story_text_match_sql].join(', ')
          )
        end
      else
        if tag_scopes.present?
          self.results = with_tags(base, tag_scopes)
        else
          self.results = base.includes({ :taggings => :tag }, :user).left_outer_joins(:story_text)
        end
      end
      self.total_results = self.results.dup.count("stories.id")

      case self.order
      when "relevance"
        if qwords.present?
          self.results.order!(Arel.sql("((#{title_match_sql}) * 2) + " +
                                       "((#{description_match_sql}) * 1.5) + " +
                                       "(#{story_text_match_sql}) DESC"))
        else
          self.results.order!("stories.created_at DESC")
        end
      when "newest"
        self.results.order!("stories.created_at DESC")
      when "points"
        self.results.order!("score DESC")
      end

    when "comments"
      base = Comment.active
      if domain.present?
        base = with_stories_in_domain(base.joins(:story), domain)
      end
      if tag_scopes.present?
        base = with_stories_matching_tags(base, tag_scopes)
      end
      if qwords.present?
        base = base.where(Arel.sql("MATCH(comment) AGAINST('#{qwords}' IN BOOLEAN MODE)"))
      end
      self.results = base.select(
        "comments.*, " +
        "MATCH(comment) AGAINST('#{qwords}' IN BOOLEAN MODE) AS rel_comment"
      ).includes(:user, :story)
      self.total_results = self.results.dup.count("comments.id")

      case self.order
      when "relevance"
        self.results.order!("rel_comment DESC")
      when "newest"
        self.results.order!("created_at DESC")
      when "points"
        self.results.order!("score DESC")
      end
    end

    # with_tags uses group_by, so count returns a hash
    self.total_results = self.total_results.count if self.total_results.is_a? Hash

    if self.page > self.page_count
      self.page = self.page_count
    end
    if self.page < 1
      self.page = 1
    end

    self.results = self.results
      .limit(self.per_page)
      .offset((self.page - 1) * self.per_page)

    # if a user is logged in, fetch their votes for what's on the page
    if user
      case what
      when "stories"
        votes = Vote.story_votes_by_user_for_story_ids_hash(user.id, self.results.map(&:id))

        self.results.each do |r|
          if votes[r.id]
            r.vote = votes[r.id]
          end
        end

      when "comments"
        votes = Vote.comment_votes_by_user_for_comment_ids_hash(user.id, self.results.map(&:id))

        self.results.each do |r|
          if votes[r.id]
            r.current_vote = votes[r.id]
          end
        end
      end
    end

  rescue ActiveRecord::StatementInvalid
    # more likely the user has entered invalid boolean mode operators than our
    # code is broken (not that I really trust this hairy class)
    self.results = []
    self.total_results = -1
  end
end
