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
  attr_reader :invalid_because, :parse_tree

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
    @results_count = params[:results_count] || -1
    @invalid_because = nil
  end

  # returns @results so perform_* can return from calling this
  def invalid reason
    @invalid_because = reason
    @results_count = 0
    @results = searched_model.none
  end

  def max_matches
    per_page * 20
  end

  def per_page
    20
  end

  def to_param
    {
      q: @q,
      what: @what,
      order: @order,
      page: @page
    }
  end

  def page_count
    total = results_count.to_i

    if total == -1 || total > max_matches
      total = max_matches
    end

    ((total - 1) / per_page.to_i) + 1
  end

  def perform!
    return (@results = searched_model.none) if q.blank? || parse_tree.blank?
    if what == :stories
      perform_story_search!
    else
      perform_comment_search!
    end
  end

  # security: must prevent sql injection
  # it assumes SearchParser prevents "
  def flatten_title tree
    if tree.keys.first == :term
      ActiveRecord::Base.connection.quote_string(tree.values.first.to_s)
    elsif tree.keys.first == :quoted
      '"' + tree.values.first.map(&:values).flatten.join(" ").gsub("'", "\\\\'") + '"'
    end
  end

  # security: must prevent sql injection
  # strip all nonword except -_' so people can search for contractions like "don't"
  # some of these are search operators, some sql injection
  # https://mariadb.com/kb/ru/full-text-index-overview/#in-boolean-mode
  # surprise: + is not in \p{Punct}
  def strip_operators s
    s.to_s
      .gsub(/[^\p{Word}']/, " ")
      .gsub("'", "\\\\'")
      .strip
  end

  # not security-sensitive, mariadb ignores 1 and 2 character terms and
  # stripping them allows the frontend to explain they're ignored
  def strip_short_terms(s)
    s.to_s.strip.split(/\p{Space}/).filter { _1.size > 2 }.join(" ")
  end

  def perform_comment_search!
    query = Comment.accessible_to_user(searcher).for_presentation

    terms = []
    n_commenters = 0
    n_domains = 0
    n_submitters = 0
    n_tags = 0
    tags = nil
    url = false
    title = false

    # array of hashes, type => value(s)
    parse_tree.each do |node|
      type, value = node.first
      case type
      when :commenter, :user
        n_commenters += 1
        return invalid("A comment only has one commenter") if n_commenters > 1
        query.joins!(:user).where!(users: {username: value.to_s})
      when :domain
        n_domains += 1
        return invalid("A story can't be from multiple domains at once") if n_domains > 1
        query.joins!(story: [:domain]).where!(story: {domains: {domain: value.to_s}})
      when :submitter
        n_submitters += 1
        return invalid("A story only has one submitter") if n_submitters > 1
        query.joins!(story: :user).where!(story: {users: {username: value.to_s}})
      when :tag
        n_tags += 1
        tags ||= Tag.none.select(:id)
        tags.or!(Tag.where(tag: value.to_s))
        # TODO unknown tag
      when :title
        title = true
        value = flatten_title value
        query.where!(
          story: Story.joins(:story_text).where(
            "MATCH(story_texts.title) AGAINST ('+#{value}' in boolean mode)"
          )
        )
      when :url
        url = true
        query
          .joins!(:story)
          .and!(
            Story.where(url: value.to_s)
              .or(Story.where(normalized_url: Utils.normalize(value)))
          )
      when :negated
        # TODO
      when :quoted
        terms.append '"' + strip_operators(value.pluck(:term).join(" ")) + '"'
      when :term, :catchall
        val = strip_short_terms(strip_operators(value))
        # if punctuation is replaced with a space, this would generate a terms search
        # AGAINST('+' in boolean mode)
        terms.append val if !val.empty?
      end
    end
    if terms.any?
      terms_sql = <<~SQL.tr("\n", " ")
        MATCH(comment)
        AGAINST ('#{terms.map { |s| "+#{s}" }.join(" ")}' in boolean mode)
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

    # don't allow blank searches for all records when strip_ removes all data
    if n_commenters == 0 &&
        n_domains == 0 &&
        n_submitters == 0 &&
        n_tags == 0 &&
        !url &&
        !title &&
        terms.empty?
      return invalid("No search terms recognized")
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
    query = Story.base(@searcher).for_presentation

    terms = []
    n_domains = 0
    n_submitters = 0
    n_tags = 0
    tags = nil
    url = false
    title = false

    # array of hashes, type => value(s)
    parse_tree.each do |node|
      type, value = node.first
      case type
      when :commenter
        return invalid("Doesn't make sense to search Stories by commenter")
      when :domain
        n_domains += 1
        return invalid("A story can't be from multiple domains at once") if n_domains > 1
        query.joins!(:domain).where!(domains: {domain: value.to_s})
      when :submitter, :user
        n_submitters += 1
        return invalid("A story only has one submitter") if n_submitters > 1
        query.joins!(:user).where!(user: {username: value.to_s})
      when :tag
        n_tags += 1
        tags ||= Tag.none.select(:id)
        tags.or!(Tag.where(tag: value.to_s))
        # TODO unknown tag
      when :title
        title = true
        value = flatten_title value
        query.joins!(:story_text).where!(
          "MATCH(story_texts.title) AGAINST ('+#{value}' in boolean mode)"
        )
      when :url
        url = true
        query.and!(
          Story.where(url: value.to_s)
            .or(Story.where(normalized_url: Utils.normalize(value)))
        )
      when :negated
        # TODO
      when :quoted
        terms.append '"' + strip_operators(value.pluck(:term).join(" ")) + '"'
      when :term, :catchall
        val = strip_short_terms(strip_operators(value))
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

    # don't allow blank searches for all records when strip_ removes all data
    if n_domains == 0 &&
        n_submitters == 0 &&
        n_tags == 0 &&
        !url &&
        !title &&
        terms.empty?
      return invalid("No search terms recognized")
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
