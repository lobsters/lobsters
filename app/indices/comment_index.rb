ThinkingSphinx::Index.define :comment, :with => :active_record do
  indexes comment
  indexes short_id
  indexes user.username, :as => :author

  has "(CAST(upvotes as #{Story.votes_cast_type}) - " <<
    "CAST(downvotes as #{Story.votes_cast_type}))", :as => :score,
    :type => :bigint, :sortable => true

  has is_deleted
  has created_at

  where sanitize_sql(:is_deleted => false, :is_moderated => false)
end
