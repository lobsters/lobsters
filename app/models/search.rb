# typed: false

# results:
#   not performed
#   nothing found
#   invalid: negative w/o positive term
#   invalid: multiple domains
#   invalid: unknown tag
#   results

class Search
  attr_reader :q, :what, :order, :page, :searcher
  attr_reader :parse_tree

  # takes untrusted params from controller, so sanitize
  def initialize params, user
    @q = params[:q]
    @parse_tree = if params[:q].present?
      SearchParser.new.parse(params[:q])
    else
      []
    end

    @what = if %w[stories comments].include? params[:what]
      params[:what].to_sym
    else
      :comments
    end

    @order = if %w[newest relevance score].include? params[:order]
      params[:order].to_sym
    else
      :newest
    end

    @page = params[:page].to_i
    @page = 1 if @page == 0

    @searcher = user

    @results = nil
    @results_count = -1
  end

  def max_matches
    100
  end

  def per_page
    20
  end

  def to_url_params
    [:q, :what, :order, :page].map { |p| "#{p}=#{CGI.escape(send(p).to_s)}" }.join("&")
  end

  def page_count
    total = results_count.to_i

    if total == -1 || total > max_matches
      total = max_matches
    end

    ((total - 1) / per_page.to_i) + 1
  end

  def perform!
    return (@results = searched_model.none) if q.nil?
    if what == :stories
      perform_story_search!
    else
      perform_comment_search!
    end
  end

  # strip all punctuation except ' so people can search for contractions like "don't"
  # some of these are search operators, some sql injection
  # https://mariadb.com/kb/ru/full-text-index-overview/#in-boolean-mode
  def strip_operators s
    s.to_s.gsub(/[\p{Punct}&&[^']]/, " ").strip
  end

  def perform_comment_search!
    query = Comment.accessible_to_user(searcher).for_presentation

    terms = []
    n_domains = 0
    n_tags = 0
    tags = nil

    # array of hashes, type => value(s)
    @parse_tree.each do |node|
      type, value = node.first
      case type
      when :domain
        n_domains += 1
        # TODO handle invalid search of multiple domains
        # raise "too many cooks" if n_domains > 1
        query.joins!(story: [:domain]).where!(story: {domains: {domain: value.to_s}})
      when :tag
        n_tags += 1
        tags ||= Tag.none.select(:id)
        tags.or!(Tag.where(tag: value.to_s))
        # TODO unknown tag
      when :negated
        # TODO
      when :quoted
        terms.append '"' + strip_operators(value).gsub("'", "\\\\'") + '"'
      when :term
        val = strip_operators(value).gsub("'", "\\\\'")
        # if punctuation is replaced with a space, this would generate a terms search
        # AGAINST('+' in boolean mode)
        terms.append val if !val.empty?
      end
    end
    if terms.any?
      terms_sql = <<~SQL.tr("\n", " ")
        MATCH(comment)
        AGAINST ('#{terms.map { |s| "+#{s}" }.join(", ")}' in boolean mode)
      SQL
      query.where! terms_sql
    end
    if tags
      query.where!(
        story: Story
                .joins(:tags)
                .where(tags: tags)
                .group("stories.id")
                .having("count(distinct tags.id) = #{n_tags}")
      )
    end

    @results_count = query.dup.count
    # with_tags uses group_by, so count returns a hash
    @results_count = @results_count.count if @results_count.is_a? Hash

    case order
    when :newest
      query.order!(id: :desc)
    when :relevance
      # relevance is undefined without search terms so sort by score
      if terms.any?
        query.order!(Arel.sql(terms_sql + " DESC"))
      else
        query.order!(score: :desc)
      end
    when :score
      query.order!(score: :desc)
    end

    query.limit!(per_page)
    query.offset!((page - 1) * per_page)
    query
  end

  def perform_story_search!
    query = Story.base(@user).for_presentation

    terms = []
    n_domains = 0
    n_tags = 0
    tags = nil

    # array of hashes, type => value(s)
    @parse_tree.each do |node|
      type, value = node.first
      case type
      when :domain
        n_domains += 1
        # TODO handle invalid search of multiple domains
        # raise "too many cooks" if n_domains > 1
        query.joins!(:domain).where!(domains: {domain: value.to_s})
      when :tag
        n_tags += 1
        tags ||= Tag.none.select(:id)
        tags.or!(Tag.where(tag: value.to_s))
        # TODO unknown tag
      when :negated
        # TODO
      when :quoted
        terms.append '"' + strip_operators(value).gsub("'", "\\\\'") + '"'
      when :term
        val = strip_operators(value).gsub("'", "\\\\'")
        # if punctuation is replaced with a space, this would generate a terms search
        # AGAINST('+' in boolean mode)
        terms.append val if !val.empty?
      end
    end
    if terms.any?
      terms_sql = <<~SQL.tr("\n", " ")
        MATCH(story_texts.title, story_texts.description, story_texts.body)
        AGAINST ('#{terms.map { |s| "+#{s}" }.join(", ")}' in boolean mode)
      SQL
      query.joins!(:story_text).where! terms_sql
    end
    if tags
      # This searches tags by subquery because otherwise Rails recognizes the join against tags and
      # thinks the .tags association preload is satisfied, so returned stories will only have the
      # searched-for tags.
      query.joins!(<<~SQL.tr("\n", "")
        inner join (
          select stories.id
          from stories
          join taggings on taggings.story_id = stories.id
          where taggings.tag_id in (#{tags.to_sql})
          group by stories.id
          having count(distinct taggings.id) = #{n_tags}
        ) as stories_with_tags on stories_with_tags.id = stories.id
      SQL
                  )
    end

    @results_count = query.dup.count

    case order
    when :newest
      query.order!(id: :desc)
    when :relevance
      # relevance is undefined without search terms so sort by score
      if terms.any?
        query.order!(Arel.sql(terms_sql + " desc"))
      else
        query.order!(score: :desc)
      end
    when :score
      query.order!(score: :desc)
    end

    query.limit!(per_page)
    query.offset!((page - 1) * per_page)
    query
  end

  def results
    @results ||= perform!
  end

  def results_count
    perform! if @results.nil?
    @results_count
  end

  def searched_model
    (what == :stories) ? Story : Comment
  end
end
