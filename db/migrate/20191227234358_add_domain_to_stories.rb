class AddDomainToStories < ActiveRecord::Migration[5.2]
  def change
    add_reference :stories, :domain, foreign_key: true
  end
end
