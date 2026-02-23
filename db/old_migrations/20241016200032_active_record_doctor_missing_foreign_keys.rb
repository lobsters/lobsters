class ActiveRecordDoctorMissingForeignKeys < ActiveRecord::Migration[7.2]
  def up
    add_foreign_key :messages, :users, column: :author_user_id

    change_column :links, :from_story_id, :bigint, unsigned: true
    add_foreign_key :links, :stories, column: :from_story_id
    change_column :links, :to_story_id, :bigint, unsigned: true
    add_foreign_key :links, :stories, column: :to_story_id
    change_column :links, :from_comment_id, :bigint, unsigned: true
    add_foreign_key :links, :comments, column: :from_comment_id
    change_column :links, :to_comment_id, :bigint, unsigned: true
    add_foreign_key :links, :comments, column: :to_comment_id

    add_foreign_key :moderations, :users
    change_column :moderations, :domain_id, :bigint
    add_foreign_key :moderations, :domains
    change_column :moderations, :category_id, :bigint
    add_foreign_key :moderations, :categories
    change_column :moderations, :origin_id, :bigint
    add_foreign_key :moderations, :origins

    add_foreign_key :stories, :origins
    add_foreign_key :tags, :categories

    add_foreign_key :origins, :domains
    change_column :origins, :banned_by_user_id, :bigint, unsigned: true
    add_foreign_key :origins, :users, column: :banned_by_user_id

    change_column :domains, :banned_by_user_id, :bigint, unsigned: true
    add_foreign_key :domains, :users, column: :banned_by_user_id
  end

  def down
    remove_foreign_key :messages, :users, column: :author_user_id

    remove_foreign_key :links, :stories, column: :from_story_id
    change_column :links, :from_story_id, :bigint, unsigned: false
    remove_foreign_key :links, :stories, column: :to_story_id
    change_column :links, :to_story_id, :bigint, unsigned: false
    remove_foreign_key :links, :comments, column: :from_comment_id
    change_column :links, :from_comment_id, :bigint, unsigned: false
    remove_foreign_key :links, :comments, column: :to_comment_id
    change_column :links, :to_comment_id, :bigint, unsigned: false

    remove_foreign_key :moderations, :users
    remove_foreign_key :moderations, :domains
    change_column :moderations, :domain_id, :int
    remove_foreign_key :moderations, :categories
    change_column :moderations, :category_id, :bigint
    remove_foreign_key :moderations, :origins
    change_column :moderations, :origin_id, :int

    remove_foreign_key :stories, :origins
    remove_foreign_key :tags, :categories

    remove_foreign_key :origins, :domains
    remove_foreign_key :origins, :users, column: :banned_by_user_id
    change_column :origins, :banned_by_user_id, :int

    remove_foreign_key :domains, :users, column: :banned_by_user_id
    change_column :origins, :banned_by_user_id, :int
  end
end
