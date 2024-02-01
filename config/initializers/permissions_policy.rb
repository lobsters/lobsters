# typed: false

# Be sure to restart your server when you modify this file.

# Define an application-wide HTTP permissions policy. For further
# information see: https://developers.google.com/web/updates/2018/06/feature-policy

# these lists are ridiculous, I need a wildcard or policy should default none for all
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Permissions_Policy
# https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/platform/feature_policy/feature_policy.cc;drc=ab90b51c5b60de15054a32b0bd18e4839536a1c9;l=138
Rails.application.config.permissions_policy do |policy|
  # commented-out settings are configured but not yet supported by the Rails DSL

  policy.accelerometer :none
  # policy.animations :none
  policy.autoplay :none
  policy.ambient_light_sensor :none
  # policy.battery :none
  # policy.browsing_topics :none
  policy.camera :none
  # policy.display_capture :none
  # policy.document_domain :none
  # policy.document_write :none
  policy.encrypted_media :none
  policy.fullscreen :none
  # policy.gamepad :none
  policy.geolocation :none
  policy.gyroscope :none
  # policy.identity_credentials_get :none
  policy.idle_detection :none
  # policy.local_fonts :none
  policy.magnetometer :none
  policy.microphone :none
  policy.midi :none
  # policy.otp_credentials :self
  policy.payment :none
  policy.picture_in_picture :none
  policy.screen_wake_lock :none
  policy.serial :none
  # policy.speaker_selection :none
  # policy.storage_access :none
  policy.sync_xhr :none
  policy.usb :none
  # policy.vertical_scroll :self
  policy.web_share :none
  # policy.window_management :none
  # policy.xr_spatial_tracking :none
end
