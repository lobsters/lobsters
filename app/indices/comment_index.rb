ThinkingSphinx::Index.define :comment, :with => :active_record do
  indexes comment
  indexes short_id
  indexes user.username, :as => :author

  has Comment.score_sql, :as => :score, :type => :bigint, :sortable => true

  has is_deleted
  has created_at

  where sanitize_sql(:is_deleted => false, :is_moderated => false)
end
