# typed: false

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :none

    # Needed for AJAX calls, mini-profiler
    policy.connect_src :self

    # Data URL used for Pushover logo in settings
    policy.img_src :self, :data
    policy.script_src :self

    # 18 inline styles to clean up before enabling this
    policy.style_src :self, :unsafe_inline
  end

  # Generate session nonces for permitted importmap and inline scripts.
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
