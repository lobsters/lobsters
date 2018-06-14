# Be sure to restart your server when you modify this file.

# match this in your nginx config for bypassing the file cache
Lobsters::Application.config.session_store :cookie_store,
                                           key: 'lobster_trap',
                                           expire_after: 1.month
