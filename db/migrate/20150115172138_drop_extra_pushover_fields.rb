class DropExtraPushoverFields < ActiveRecord::Migration[5.1]
  # extra pushover data is now stored in the subscription, we don't need it
  #
  # user keys to subscription keys can be migrated by using
  # https://pushover.net/api/subscriptions#migration

  def change
    remove_column :users, :pushover_device
    remove_column :users, :pushover_sound
  end
end
