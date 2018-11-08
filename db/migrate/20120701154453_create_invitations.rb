# If you are reading this file because Rails complains that there isn't a
# version on this migration, stop.
#
# Create your database with `rails db:schema:load`, not by running all these.
# We have migrations to migrate live databases, not create them, and we do not
# want a PR to 'fix' migrations.
class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.integer :user_id
      t.string :email
      t.string :code
      t.timestamps :null => false
    end

    add_column :users, :invited_by_user_id, :integer
  end
end
