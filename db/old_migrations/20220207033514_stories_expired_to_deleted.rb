class StoriesExpiredToDeleted < ActiveRecord::Migration[6.1]
  def change
    rename_column :stories, :is_expired, :is_deleted
  end
end
