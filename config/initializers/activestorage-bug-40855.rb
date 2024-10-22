# typed: false

# https://github.com/rails/rails/issues/40855
# This misdesign of ActiveStorage being unable to generate URLs outside of a request cycle echos the
# URL generation misdesign that's been in Rails from the start, as if generating URLs were not
# essential to a web app.
#
# This file fixes the Rails console.
# See 'include ActiveStorage::SetCurrent' in ApplicationController for the fix to dev/test modes.
#
# Workaround is here to be easy to delete should the midesign get fixed:
# https://github.com/rails/rails/issues/40855#issuecomment-2350744657

Rails.application.config.after_initialize do
  ActiveStorage::Current.url_options = {
    host: Rails.application.domain,
    protocol: Rails.application.ssl? ? "https" : "http",
    port: Rails.env.production? ? nil : 3000
  }
end
