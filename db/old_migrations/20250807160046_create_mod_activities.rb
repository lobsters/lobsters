class CreateModActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :mod_activities do |t|
      t.references :item, polymorphic: true, null: false, type: :bigint, unsigned: true
      t.string :token, null: false

      t.timestamps

      t.index [:item_type, :item_id], unique: true
      t.index [:token], unique: true
    end

    Moderation.find_each { ModActivity.create_for!(it) }
    ModNote.find_each { ModActivity.create_for!(it) }
  end
end
