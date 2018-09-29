class NormalizeIdsAndFks < ActiveRecord::Migration[5.2]
  def change
    # ids
    change_column :comments,            :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :hat_requests,        :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :hats,                :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :hidden_stories,      :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :invitation_requests, :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :invitations,         :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :messages,            :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :moderations,         :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :mod_notes,           :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :read_ribbons,        :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :saved_stories,       :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :stories,             :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :suggested_taggings,  :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :suggested_titles,    :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :tag_filters,         :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :taggings,            :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :tags,                :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :users,               :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true
    change_column :votes,               :id,                         :bigint, unsigned: true, unique: true, null: false, auto_increment: true

    # FKs
    change_column :comments,           :hat_id,                     :bigint, unsigned: true
    change_column :comments,           :parent_comment_id,          :bigint, unsigned: true
    change_column :comments,           :story_id,                   :bigint, unsigned: true, null: false
    change_column :comments,           :thread_id,                  :bigint, unsigned: true
    change_column :comments,           :user_id,                    :bigint, unsigned: true, null: false
    change_column :hat_requests,       :user_id,                    :bigint, unsigned: true, null: false
    change_column :hats,               :granted_by_user_id,         :bigint, unsigned: true, null: false
    change_column :hats,               :user_id,                    :bigint, unsigned: true, null: false
    change_column :hidden_stories,     :story_id,                   :bigint, unsigned: true, null: false
    change_column :hidden_stories,     :user_id,                    :bigint, unsigned: true, null: false
    change_column :invitations,        :new_user_id,                :bigint, unsigned: true
    change_column :invitations,        :user_id,                    :bigint, unsigned: true, null: false
    change_column :messages,           :author_user_id,             :bigint, unsigned: true, null: false
    change_column :messages,           :hat_id,                     :bigint, unsigned: true
    change_column :messages,           :recipient_user_id,          :bigint, unsigned: true, null: false
    change_column :moderations,        :comment_id,                 :bigint, unsigned: true
    change_column :moderations,        :moderator_user_id,          :bigint, unsigned: true
    change_column :moderations,        :story_id,                   :bigint, unsigned: true
    change_column :moderations,        :tag_id,                     :bigint, unsigned: true
    change_column :moderations,        :user_id,                    :bigint, unsigned: true
    change_column :mod_notes,          :moderator_user_id,          :bigint, unsigned: true, null: false
    change_column :mod_notes,          :user_id,                    :bigint, unsigned: true, null: false
    change_column :read_ribbons,       :story_id,                   :bigint, unsigned: true, null: false
    change_column :read_ribbons,       :user_id,                    :bigint, unsigned: true, null: false
    change_column :saved_stories,      :story_id,                   :bigint, unsigned: true, null: false
    change_column :saved_stories,      :user_id,                    :bigint, unsigned: true, null: false
    change_column :stories,            :merged_story_id,            :bigint, unsigned: true
    change_column :stories,            :user_id,                    :bigint, unsigned: true, null: false
    change_column :suggested_taggings, :story_id,                   :bigint, unsigned: true, null: false
    change_column :suggested_taggings, :tag_id,                     :bigint, unsigned: true, null: false
    change_column :suggested_taggings, :user_id,                    :bigint, unsigned: true, null: false
    change_column :suggested_titles,   :story_id,                   :bigint, unsigned: true, null: false
    change_column :suggested_titles,   :user_id,                    :bigint, unsigned: true, null: false
    change_column :tag_filters,        :tag_id,                     :bigint, unsigned: true, null: false
    change_column :tag_filters,        :user_id,                    :bigint, unsigned: true, null: false
    change_column :taggings,           :story_id,                   :bigint, unsigned: true, null: false
    change_column :taggings,           :tag_id,                     :bigint, unsigned: true, null: false
    change_column :users,              :banned_by_user_id,          :bigint, unsigned: true
    change_column :users,              :disabled_invite_by_user_id, :bigint, unsigned: true
    change_column :users,              :invited_by_user_id,         :bigint, unsigned: true
    change_column :votes,              :comment_id,                 :bigint, unsigned: true
    change_column :votes,              :story_id,                   :bigint, unsigned: true, null: false
    change_column :votes,              :user_id,                    :bigint, unsigned: true, null: false
  end
end
