class FetchAvatars < ActiveRecord::Migration[7.2]
  def up
    # FileUtils.remove_dir(Rails.public_path.join("avatars/").to_s)
  end

  def down
  end
end
