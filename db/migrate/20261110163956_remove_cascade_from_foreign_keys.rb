class RemoveCascadeFromForeignKeys < ActiveRecord::Migration[8.1]
   def up
     remove_foreign_key :taggings, :tags
     add_foreign_key :taggings, :tags

     remove_foreign_key :votes, :comments
     add_foreign_key :votes, :comments
   end

   def down
     remove_foreign_key :taggings, :tags
     add_foreign_key :taggings, :tags, on_update: :cascade, on_delete: :cascade

     remove_foreign_key :votes, :comments
     add_foreign_key :votes, :comments, on_update: :cascade, on_delete: :cascade
   end
 end
