class FixPrefersContrast < ActiveRecord::Migration[8.0]
  def change
    User.find_each do |u|
      next unless u.prefers_contrast == false || u.prefers_contrast == true
      u.prefers_contrast = :system
      u.save! validate: false
    end
  end
end
