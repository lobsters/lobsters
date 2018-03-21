class AddKarmaToUsers < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :karma, :integer, :default => 0, :null => false

    Keystore.transaction do
      User.lock(true).select(:id).each do |u|
        u.update_column :karma, Keystore.value_for("user:#{u.id}:karma").to_i
      end

      Keystore.where(Keystore.arel_table[:key].matches("user:%:karma")).delete_all
    end
  end

  def down
    Keystore.transaction do
      User.select(:id, :karma).each do |u|
        Keystore.put("user:#{u.id}:karma", u.karma)
      end
    end

    remove_column :users, :karma
  end
end
