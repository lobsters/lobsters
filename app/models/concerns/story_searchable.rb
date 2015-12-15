module StorySearchable
  extend ActiveSupport::Concern


  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    include Searchable

    settings do
      mappings dynamic: false do
        indexes :user do
          indexes :name , :as => :author
        end
        indexes :description
        indexes :short_id
        indexes :title
        indexes :url
        indexes :story_cache
        indexes :tags, type: 'multi_field' do
          indexes :tag, boost: 10
          indexes :sort, analyzer: 'sortable'
        end
        indexes :created_at
        indexes :id, :as => :story_id
        indexes :hotness
        indexes :is_expired
        indexes :score_sql, :as => :score, :type => :long

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


  end

  def as_indexed_json(options={})
    indexed_json = {}

    indexed_json[:description] = send(:description)
    indexed_json["tags"] = tags.map { |tag| tag.name }.join(" ")
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
