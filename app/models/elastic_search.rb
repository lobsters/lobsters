class ElasticSearch
  include ActiveModel::Model

  attr_reader :results, :total_results
  attr_accessor :q, :order, :page, :per_page, :what

  validates :q, length: { :minimum => 2 }
  validates :order, inclusion: { in: %w(relevance newest points) }
  validates :what, inclusion: { in: %w(stories comments) }

  class << self
    def index
      'lobsters-search'
    end

    def client
      Elasticsearch::Client.new
    end
  end

  def initialize(attributes = {})
    super
    @page ||= 0
    @per_page ||= 25
    @order ||= 'relevance'
    @what ||= 'stories'

    @results = []
    @total_results = -1
    @votes = {}
  end

  def type
    case @what
    when 'stories'
      'story'
    when 'comments'
      'comment'
    end
  end

  def sort
    term = case @order
    when 'relevance'
      '_score'
    when 'newest'
      'created_at'
    when 'points'
      'score'
    end

    "#{term}:asc"
  end

  def search_for_user!(user)
    query = query_for_user(user, type)
    response = self.class.client.search(
      index: self.class.index,
      q: query,
      size: @per_page,
      from: (@page * @per_page),
      sort: sort
    )

    ids = response['hits']['hits'].map {|h| GlobalID::Locator.locate(h['_id']).id }

    @total_results = response['hits']['total']

    case @what
    when 'stories'
      @results = Story.where(id: ids)
      @votes = Vote.story_votes_by_user_for_story_ids_hash(user.id, ids) if user
    when 'comments'
      @results = Comment.where(id: ids)
      @votes = Vote.comment_votes_by_user_for_comment_ids_hash(user.id, ids) if user
    end

    @results.each {|r| r.vote = @votes[r.id] if r.respond_to?(:"vote=") && @votes[r.id] }
  end

private

  def query_for_user(user, type)
    tag_filters = user ? user.tag_filters.map {|t| "NOT tag:#{t.name}" } : []
    expiration_filter = user && user.is_admin? ? '' : 'NOT is_expired:true'
    [@q, "AND kind:#{type}", tag_filters, expiration_filter].flatten.join(' ')
  end
end
