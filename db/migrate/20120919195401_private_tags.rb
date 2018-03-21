class PrivateTags < ActiveRecord::Migration[5.1]
  def up
    add_column :tags, :privileged, :boolean, :default => false

    # All existing tags should be public by default
    Tag.all.each do |t|
      t.privileged = false
      t.save
    end
  end

  def down
    remove_column :tags, :privileged
  end
end
