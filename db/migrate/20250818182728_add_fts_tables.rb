class AddFtsTables < ActiveRecord::Migration[8.0]
  def change
    # create preferred contentless-delete tables as described in:
    # https://www.sqlite.org/fts5.html#contentless_delete_tables
    create_virtual_table :comments_fts, :fts5, ["comment", "content=''", "contentless_delete=1"]
    create_virtual_table :story_texts_fts, :fts5, ["title", "description", "body", "content=''", "contentless_delete=1"]
  end
end
