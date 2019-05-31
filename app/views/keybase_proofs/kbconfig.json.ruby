# see https://keybase.io/docs/proof_integration_guide#1-config

JSON.pretty_generate({
  "version": 1,
  "domain": @domain,
  "display_name": @name,
  "description": @description,
  "brand_color": @brand_color,
  "logo": {
    "svg_black": @logo_black,
    "svg_full": @logo_full
  },
  "username": {
    "re": @user_re,
    "min": 1,
    "max": 25
  },
  "prefill_url": @prefill_url,
  "profile_url": @profile_url,
  "check_url": @check_url,
  "check_path": ["keybase_signatures"],
  "avatar_path": ["avatar_url"],
  "contact": @contacts
})
