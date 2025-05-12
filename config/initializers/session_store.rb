# typed: false

# Be sure to restart your server when you modify this file.

# match this in nginx config for bypassing the file cache
Lobsters::Application.config.session_store :cookie_store,
  expire_after: 1.month,
  httponly: true,
  key: "lobster_trap",
  same_site: :strict,
  secure: true
