# typed: false

# Be sure to restart your server when you modify this file.

# match this in caddy config for bypassing the file cache
Lobsters::Application.config.session_store :cookie_store,
  key: "lobster_trap",
  expire_after: 1.month,
  httponly: true,
  same_site: :strict
# :secure commented out because it's redundant with config.force_ssl
# https://api.rubyonrails.org/v5.2.8.1/classes/ActionDispatch/SSL.html
# secure: true
