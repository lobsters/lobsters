# typed: false

# Be sure to restart your server when you modify this file.

# match this in caddy config for bypassing the file cache
Lobsters::Application.config.session_store :cookie_store,
  key: "lobster_trap",
  expire_after: 1.month,
  httponly: true,
  # :same_site isn't :strict because users who navigate from email/mastodon/etc links get that first
  # page logged out, then their next page is logged in, both of which look like the site security code
  # has big bugs.
  # https://developer.mozilla.org/en-US/docs/Web/Security/Practical_implementation_guides/Cookies#samesite
  same_site: :lax
# :secure commented out because it's redundant with config.force_ssl; if it's set in the test env
# the tests fail because they access via http https://api.rubyonrails.org/v5.2.8.1/classes/ActionDispatch/SSL.html
# secure: true
