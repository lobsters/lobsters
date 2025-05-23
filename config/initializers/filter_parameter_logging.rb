# typed: false

# include a comment explaining where each token is used, or 'preventative' if it's obviously
# sensitive and likely to be used, or used in a popular tool like Devise

# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :authenticity_token, # all forms
  :certificate, # preventative
  :crypt, # preventative
  :_key, # preventative
  :lobster_trap, # session cookie
  :otp, # preventative
  :password_confirmation, # LoginController (redundant with passw)
  :password, # LoginController (redundant with passw)
  :password_token, # LoginController
  :passw, # preventative
  :salt, # preventative
  :secret, # preventative
  :session_token, # auth cookie value
  :token, # rss token - need to transition this to a typeid
  :totp_code # LoginController
]
