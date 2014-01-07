
ThinkingSphinx::Index.define :story, :with => :active_record do
  indexes url
  indexes title
  indexes description
  indexes user.username, :as => :author
  indexes tags(:tag), :as => :tags

  has created_at, :sortable => true
  has hotness, is_expired
  has "(cast(upvotes as signed) - cast(downvotes as signed))",
    :as => :score, :type => :bigint, :sortable => true

  set_property :field_weights => {
    :upvotes => 15,
    :title => 10,
    :tags => 5,
  }

  where sanitize_sql(:is_expired => false)
end
