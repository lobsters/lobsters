module StorySearchable
  extend ActiveSupport::Concern


  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks
    #include Elasticsearch::Persistence::Model
     #attribute :taken_at, Date
     #attribute :description, String, mapping: { type: 'string', analyzer: 'en_analyzer', copy_to: 'bigram' }

    include Searchable

    settings do
      mappings dynamic: false do
        # indexes :user do
        #   indexes :name ,  :copy_to => 'author'#, :as => :author
        # end
        indexes :name ,  :copy_to => 'author'#, :as => :author
        indexes :description, :boost => 10
        indexes :short_id
        indexes :title
        indexes :url
        indexes :story_cache
        indexes :tags, type: 'multi_field' do
          indexes :tag, boost: 10
          indexes :sort, analyzer: 'sortable'
        end
        indexes :created_at, index: :not_analyzed
        indexes :id, :type => 'long' , :copy_to => 'story_id' #, index: :not_analyzed
        indexes :hotness, index: :not_analyzed
        indexes :is_expired, index: :not_analyzed
        indexes :score_sql , :copy_to => 'score', :type => :long, :index => :not_analyzed #, :as => :score, :type => :long, index: :not_analyzed

        # indexes :city, type: 'multi_field' do
        #   indexes :city, boost: 10
        #   indexes :sort, analyzer: 'sortable'
        # end
        #
        # indexes :region, type: 'multi_field' do
        #   indexes :region, boost: 10
        #   indexes :sort, analyzer: 'sortable'
        # end
      end
    end

    __elasticsearch__.create_index!

  end

  def as_indexed_json(options={})
    indexed_json = {}

    indexed_json[:description] = send(:description)
    indexed_json[:id] = send(:id)
    indexed_json[:short_id] = send(:short_id)
    indexed_json[:title] = send(:title)
    indexed_json[:url] = send(:url)
    indexed_json[:story_cache] = send(:story_cache)
    indexed_json[:created_at] = send(:created_at)
    indexed_json[:hotness] = send(:hotness)
    indexed_json[:is_expired] = send(:is_expired)
    indexed_json[:score_sql] = send(:upvotes) - send(:downvotes)
    indexed_json[:user] = send(:user).username
    #indexed_json["tags"] = tags.map { |tag| tag.name }.join(" ")
    indexed_json.as_json
  end


  module ClassMethods
      # def fulltext_search(search_word)
      #
      #   search_definition = {
      #     query: {
      #       multi_match: {
      #         fields: ANALYZE_INDEXES.map { |index_name| index_name },
      #         query: search_word
      #       }
      #     }
      #   }
      #
      #   search(search_definition)
      # end
      # fields = %w(message^10 sha^5 author.name^2 author.email^2 committer.name committer.email).map {|i| "commit.#{i}"}

      def trigram_search(query)
        search_definition = {
          query: {
            multi_match: {
              query: query
              # fields: %w(name)
            }
          }
        }
        __elasticsearch__.search search_definition
      end


    def self.included(base)
      base.extend ClassMethods
    end

  end
end
