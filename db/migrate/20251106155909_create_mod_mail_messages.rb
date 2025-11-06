class CreateModMailMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :mod_mail_messages do |t|
      t.references :mod_mail, null: false, foreign_key: true
      t.text :message, size: :medium, null: false
      t.references :user, null: false, foreign_key: true, type: :bigint, unsigned: true, index: false

      t.timestamps
    end
  end
end
