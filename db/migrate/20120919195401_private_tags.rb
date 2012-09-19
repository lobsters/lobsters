class PrivateTags < ActiveRecord::Migration
  def up
    add_column :tags, :private, :boolean, :default => false

    # All existing tags should be public by default
    Tag.all.each do |t|
      t.private = false
      t.save
    end
  end

  def down
    remove_column :tags, :private
  end
end
