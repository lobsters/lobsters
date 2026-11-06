class AddHotspotDocsCommentForeignKey < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :hotspot_docs, :comments
  end
end
