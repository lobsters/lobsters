if Rails.env.production?
  Prosopite.custom_logger = Logger.new("/srv/lobste.rs/log/n_plus_one_detection.log")
else
  Prosopite.raise = true
end
