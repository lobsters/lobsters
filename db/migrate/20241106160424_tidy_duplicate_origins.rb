class TidyDuplicateOrigins < ActiveRecord::Migration[7.2]
  def up
    Origin.select(:identifier).group(:identifier).having("count(*) > 1").pluck(:identifier).each do |identifier|
      primary, *dupes = Origin.where(identifier: identifier).to_a

      # reassign to ensure correct Domain is associated
      primary.identifier = identifier

      # move Stories from dupes and destroy them
      dupes.each do |dupe|
        dupe.stories.update_all(origin_id: primary.id)
        dupe.destroy!
      end
    end

    add_index :origins, :identifier, unique: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
