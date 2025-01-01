# typed: false

# This file is a relic of how Lobsters used to manage API keys and some other config variables.
# It only exists to give developers and sister sites an error message as they setup.

if Rails.application.credentials.secret_key_base.blank?
  config = <<~CONFIG
    ** SETUP REQUIRED

    The lobsters codebase manages API keys using the new (to us) Rails credentials feature.

    Look for "credentials" in README.md for setup instructions and a template.
  CONFIG
  migrate = <<~MIGRATE

    If you used the old config/initializers/production.rb method, your API keys are there and can be removed from that file after copying them to credentials.
  MIGRATE

  if Rails.env.production?
    raise config + migrate
  else
    raise config
  end
end
