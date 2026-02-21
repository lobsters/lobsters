class FixPrefersContrast < ActiveRecord::Migration[8.0]
  def change
    User.find_each do |u|
      next if ["system", "normal", "high"].include?(u.prefers_contrast)
      u.prefers_contrast = "system"
      u.save! validate: false
    end
  end
end
