class AddActiveStoriesToDomain < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :active_stories_count, :integer, default: 0
  end
end
