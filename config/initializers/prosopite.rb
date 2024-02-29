if Rails.env.production?
  Prosopite.custom_logger = Logger.new("log/n_plus_one_detection.log")
else
  Prosopite.raise = true
end
