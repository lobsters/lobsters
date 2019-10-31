class AddNormalizedDomainToStories < ActiveRecord::Migration[5.2]
  def change
    add_column :stories, :normalized_domain, :string
  end
end
