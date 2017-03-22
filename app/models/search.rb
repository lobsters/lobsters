class Search
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::AttributeMethods
  extend ActiveModel::Naming

  attr_accessor :q, :what, :order
  attr_accessor :results, :page, :total_results, :per_page

  validates_length_of :q, :minimum => 2

  def initialize
    @q = ""
    @what = "all"
    @order = "relevance"

    @page = 1
    @per_page = 20

    @results = []
    @total_results = -1
  end

  def max_matches
    ThinkingSphinx::Configuration.instance.settings["max_matches"] || 1000
  end

  def persisted?
    false
  end

  def to_url_params
    [ :q, :what, :order ].map{|p| "#{p}=#{CGI.escape(self.send(p).to_s)}"
      }.join("&amp;")
  end

  def page_count
    total = self.total_results.to_i

    if total == -1 || total > self.max_matches
      total = self.max_matches
    end

    ((total - 1) / self.per_page.to_i) + 1
  end

  def search_for_user!(user)
    opts = {
      :ranker   => :bm25,
      :page     => [ self.page, self.page_count ].min,
      :per_page => self.per_page,
      :include  => [ :story, :user ],
    }

    if order == "newest"
      opts[:order] = "created_at DESC"
    elsif order == "points"
      opts[:order] = "score DESC"
    end

    # extract domain query since it must be done separately
    domain = nil
    words = self.q.to_s.split(" ").reject{|w|
      if m = w.match(/^domain:(.+)$/)
        domain = m[1]
      end
    }.join(" ")

    if domain.present?
      self.what = "stories"
      begin
        reg = Regexp.new("//([^/]*\.)?#{domain}/")
      rescue RegexpError
        return false
      end

      story_ids = Story.select(:id).where("`url` REGEXP '" +
        ActiveRecord::Base.connection.quote_string(reg.source) + "'").
        collect(&:id)

      if story_ids.any?
        opts[:with] = { :story_id => story_ids }
      else
        self.results = []
        self.total_results = 0
        self.page = 0
        return false
      end
    end

    opts[:classes] = case what
      when "all"
        [ Story, Comment ]
      when "comments"
        [ Comment ]
      when "stories"
        [ Story ]
      else
        []
      end

    query = Riddle.escape(words)

    # go go gadget search
    self.total_results = -1
    self.results = ThinkingSphinx.search query, opts
    self.total_results = self.results.total_entries

    if self.page > self.page_count
      self.page = self.page_count
    end

    # bind votes for both types

    if opts[:classes].include?(Comment) && user
      votes = Vote.comment_votes_by_user_for_comment_ids_hash(user.id,
        self.results.select{|r| r.class == Comment }.map{|c| c.id })

      self.results.each do |r|
        if r.class == Comment && votes[r.id]
          r.current_vote = votes[r.id]
        end
      end
    end

    if opts[:classes].include?(Story) && user
      votes = Vote.story_votes_by_user_for_story_ids_hash(user.id,
        self.results.select{|r| r.class == Story }.map{|s| s.id })

      self.results.each do |r|
        if r.class == Story && votes[r.id]
          r.vote = votes[r.id]
        end
      end
    end

  rescue ThinkingSphinx::ConnectionError => e
    self.results = []
    self.total_results = -1
    raise e
  end
end
