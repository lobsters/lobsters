class CreateModMailReferences < ActiveRecord::Migration[8.0]
  def change
    create_table :mod_mail_references do |t|
      t.references :mod_mail, null: false, foreign_key: true
      t.references :reference, null: false, polymorphic: true

      t.timestamps
    end
  end
end
