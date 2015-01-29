ThinkingSphinx::Index.define :story, :with => :active_record do
  indexes description
  indexes short_id
  indexes tags(:tag), :as => :tags
  indexes title
  indexes url
  indexes user.username, :as => :author
  indexes story_cache

  has created_at, :sortable => true
  has hotness, is_expired
  has Story.score_sql, :as => :score, :type => :bigint, :sortable => true

  # opts[:with] = { :id => ... } doesn't seem to work when sphinx searches on
  # story_core, so give this column a different name to restrict on
  has id, :as => :story_id

  set_property :field_weights => {
    :upvotes => 15,
    :title => 10,
    :story_cache => 10,
    :tags => 5,
  }

  where sanitize_sql(:is_expired => false)
end
