
ThinkingSphinx::Index.define :comment, :with => :active_record do
  indexes comment
  indexes short_id
  indexes user.username, :as => :author

  has "(cast(upvotes as integer) - cast(downvotes as integer))",
    :as => :score, :type => :bigint, :sortable => true

  has is_deleted
  has created_at

  where sanitize_sql(:is_deleted => false, :is_moderated => false)
end
