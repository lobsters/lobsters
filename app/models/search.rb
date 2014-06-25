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
    @total_results = 0
  end

  def persisted?
    false
  end

  def to_url_params
    [ :q, :what, :order ].map{|p| "#{p}=#{CGI.escape(self.send(p).to_s)}"
      }.join("&amp;")
  end

  def page_count
    (total_results.to_i - 1) / per_page.to_i + 1
  end

  def search_for_user!(user)
    opts = {
      :ranker   => :bm25,
      :page     => @page,
      :per_page => @per_page,
      :include  => [ :story, :user ],
    }

    if order == "newest"
      opts[:order] = "created_at DESC"
    elsif order == "points"
      opts[:order] = "score DESC"
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

    # escape sphinx special chars (using Riddle.escape removes boolean support)
    query = self.q.gsub(/([\/~"])/, '\\\\\1')

    # go go gadget search
    @results = []
    @total_results = 0
    begin
      @results = ThinkingSphinx.search query, opts
      @total_results = @results.total_entries
    rescue => e
      Rails.logger.info "Error from Sphinx: #{e.inspect}"
    end

    # bind votes for both types

    if opts[:classes].include?(Comment) && user
      votes = Vote.comment_votes_by_user_for_comment_ids_hash(user.id,
        @results.select{|r| r.class == Comment }.map{|c| c.id })

      @results.each do |r|
        if r.class == Comment && votes[r.id]
          r.current_vote = votes[r.id]
        end
      end
    end

    if opts[:classes].include?(Story) && user
      votes = Vote.story_votes_by_user_for_story_ids_hash(user.id,
        @results.select{|r| r.class == Story }.map{|s| s.id })

      @results.each do |r|
        if r.class == Story && votes[r.id]
          r.vote = votes[r.id][:vote]
        end
      end
    end
  end
end
