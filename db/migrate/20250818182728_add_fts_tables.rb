# If you are reading this file because Rails complains that there isn't a
# version on this migration, stop.
#
# Create your database with `rails db:schema:load`, not by running all these.
# We have migrations to migrate live databases, not create them, and we do not
# want a PR to 'fix' migrations.
class AddFtsTables < ActiveRecord::Migration[8.0]
  def change
    # create preferred contentless-delete tables as described in:
    # https://www.sqlite.org/fts5.html#contentless_delete_tables
    create_virtual_table :comments_fts, :fts5, ["comment", "content=''", "contentless_delete=1"]
    create_virtual_table :story_texts_fts, :fts5, ["title", "description", "body", "content=''", "contentless_delete=1"]
  end
end
