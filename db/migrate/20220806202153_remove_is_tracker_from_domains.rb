class RemoveIsTrackerFromDomains < ActiveRecord::Migration[7.0]
  def change
    if ActiveRecord::Base.connection.column_exists?(:domains, :is_tracker)
      remove_column :domains, :is_tracker, :boolean
    end
  end
end
