module StorySearchable
  extend ActiveSupport::Concern


  included do
    include Elasticsearch::Model
   include Elasticsearch::Model::Callbacks

    include Searchable
    belongs_to :user

    settings do
      mapping do
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



  # def as_indexed_json(options={})
  #   # indexed_json = {}
  #      {
  #        name: name,
  #        sensory_tags: sensory_tags,
  #        notes: notes,
  #        name_suggest: {
  #          input: name.split(/\b/),
  #          output: name,
  #          payload: {
  #            resource_id: id,
  #            color: color
  #          }
  #        }
  #      }
  #   # NOT_ANALYZE_INDEXES.each do |index_name, index_type|
  #   #   indexed_json[index_name] = send(index_name)
  #   # end
  #   #
  #   # ANALYZE_INDEXES.each do |index_name|
  #   #   indexed_json[index_name] = send(index_name)
  #   # end
  #   #
  #   # indexed_json["tags"] = tags.map { |tag| tag.name }.join(" ")
  #   #
  #   # indexed_json.as_json
  # end

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
  end
end
