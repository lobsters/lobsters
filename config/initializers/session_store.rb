# Be sure to restart your server when you modify this file.

Lobsters::Application.config.session_store :cookie_store,
  key: 'lobster_trap', expire_after: 1.month
