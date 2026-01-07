class CreateModMailRecipients < ActiveRecord::Migration[8.0]
  def change
    create_table :mod_mail_recipients do |t|
      t.references :mod_mail, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, type: :bigint, unsigned: true, index: false

      t.timestamps
    end
  end
end
