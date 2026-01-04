class CreateModMails < ActiveRecord::Migration[8.0]
  def change
    create_table :mod_mails do |t|
      t.string :subject, null: false
      t.datetime :remind_mods_at

      t.timestamps
    end
  end
end
