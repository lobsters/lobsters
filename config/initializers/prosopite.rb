# typed: false

if Rails.env.production?
  Prosopite.rails_logger = true
  Prosopite.raise = false
end
