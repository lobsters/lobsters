# typed: false

if Rails.env.production?
  Prosopite.custom_logger = Logger.new("/srv/lobste.rs/log/n_plus_one_detection.log")
else
  Prosopite.rails_logger = true
  Prosopite.raise = true
end
