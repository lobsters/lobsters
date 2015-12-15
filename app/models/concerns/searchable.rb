module Searchable
  extend ActiveSupport::Concern

  # Custom index settings for elastic search
    INDEX_SETTINGS = {
      analysis: {
        tokenizer: {
          ngram_tokenizer: {
            type: "nGram",
            min_gram: "1",
            max_gram: "15",
            token_chars: [ "letter", "digit" ]
          }
        },
        analyzer: {
          normalized: {
            tokenizer: "keyword",
            filter:  %w{asciifolding lowercase},
            type: "custom"
          },
          all_normalized: {
            tokenizer: "standard",
            filter:  %w{asciifolding lowercase},
            type: "custom"
          },
          default: {
            type: "custom",
            tokenizer: "ngram_tokenizer",
            filter: ["lowercase"]
          },
          sortable: {
            tokenizer: 'keyword',
            filter: ["lowercase"]
          }
        }
      }
    }


  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    index_name table_name

    after_save(){
      __elasticsearch__.index_document
      true
    }

    after_touch() {
      __elasticsearch__.index_document
      true
    }

    settings INDEX_SETTINGS do
      mapping  "_all" => {
        enabled: true,
        index: :analyzed,
        analyzer: :all_normalized,
      },
      _source: { enabled: true },
      dynamic: 'false',
      "dynamic_templates" => [
          template: {
            match: "*",
            match_mapping_type: "string",
            mapping: {
              type: "multi_field",
              fields: {
                "{name}" => {
                  type: :string,
                  index: :analyzed,
                  analyzer: :normalized,
                  null_value: :null
                }
              }
            }
          }
        ] do

        # indexes :id,                  type: :string, index: :not_analyzed
        # indexes :event_collection,    type: :string, analyzer: :normalized
        # indexes :event_collection_id, type: :string, index: :not_analyzed
        # indexes :project_id,          type: :string, index: :not_analyzed
        # indexes :created_at,          type: 'date', include_in_all: false
        # indexes :data,                type: :object, index: :not_analyzed

      end

    end


  end


  def touch
      reload
      super
    end

  # def as_indexed_json(options = {})
  #    {
  #      name: name,
  #      sensory_tags: sensory_tags,
  #      notes: notes,
  #      name_suggest: {
  #        input: name.split(/\b/),
  #        output: name,
  #        payload: {
  #          resource_id: id,
  #          color: color
  #        }
  #      }
  #    }
  #  end

end
