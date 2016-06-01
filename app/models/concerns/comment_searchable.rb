module CommentSearchable
  extend ActiveSupport::Concern


  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    include Searchable

    settings do
      mappings dynamic: false do
        indexes :comment , :boost => 10, :analyzer => "normalized"
        indexes :short_id
        indexes :score_sql , :copy_to => 'score', :type => :long, :index => :not_analyzed #, :as => :score, :type => :long, index: :not_analyzed
        indexes :is_deleted , :type => 'boolean', :index => :not_analyzed
        indexes :created_at , :index => :not_analyzed
      end
    end

  #  __elasticsearch__.create_index!

  end

  def as_indexed_json(options={})
    indexed_json = {}

    indexed_json[:comment] = send(:comment)
    indexed_json[:short_id] = send(:short_id)
    indexed_json[:score_sql] = send(:upvotes) - send(:downvotes)
    indexed_json[:user] = send(:user).username
    indexed_json[:is_deleted] = send(:is_deleted)
    indexed_json[:created_at] = send(:created_at)

    indexed_json.as_json
  end


  module ClassMethods

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
