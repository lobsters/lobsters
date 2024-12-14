class AddFulltextIndexesToStoryTexts < ActiveRecord::Migration[8.0]
  def up
    execute "ALTER TABLE story_texts ADD FULLTEXT(title)"
    execute "ALTER TABLE story_texts ADD FULLTEXT(description)"
    execute "ALTER TABLE story_texts ADD FULLTEXT(body)"
  end

  def down
    execute "ALTER TABLE story_texts DROP INDEX title"
    execute "ALTER TABLE story_texts DROP INDEX description"
    execute "ALTER TABLE story_texts DROP INDEX body"
  end
end
