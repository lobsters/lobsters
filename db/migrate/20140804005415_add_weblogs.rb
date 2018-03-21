class AddWeblogs < ActiveRecord::Migration[5.1]
  def change
    create_table :weblogs do |t|
      t.timestamps
      t.integer :user_id
      t.string :title, :limit => 512
      t.string :url, :limit => 512
      t.string :site_title, :limit => 512
      t.string :site_url, :limit => 512
      t.text :content, :limit => 16777215 # mediumtext
      t.text :tags
      t.string :uuid
    end

    # why can't the charset be specified in the create_table?
    execute("ALTER TABLE weblogs MODIFY `uuid` varchar(200) CHARACTER SET utf8")

    add_index "weblogs", ["user_id", "uuid"], :name => "user_and_uuid",
      :unique => true
  end
end
