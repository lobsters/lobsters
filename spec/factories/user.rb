# typed: false

FactoryBot.define do
  factory :user do
    created_at { Time.current - (User::NEW_USER_DAYS + 1).days } # default to experience
    sequence(:email) { |n| "user-#{n}@example.com" }
    sequence(:username) { |n| "username#{n}" }
    password { "blah blah" }
    password_confirmation(&:password)
    last_read_newest_story { 1.hour.ago }
    last_read_newest_comment { 1.hour.ago }
    trait(:banned) do
      transient do
        banner { nil }
      end
      banned_at { Time.current }
      banned_reason { "some reason" }
      banned_by_user_id { banner&.id }
    end
    trait(:noinvite) do
      transient do
        disabler { nil }
      end
      disabled_invite_at { Time.current }
      disabled_invite_reason { "some reason" }
      disabled_invite_by_user_id { disabler&.id }
    end
    trait(:inactive) do
      username { "inactive-user" }
      to_create { |user| user.save(validate: false) }
    end
    trait(:deleted) do
      deleted_at { Time.current }
    end
    trait(:new) do
      deleted_at { 1.day.ago }
    end
    # users who were banned/deleted before a server move
    # you must also add banned/deleted trait with this
    trait(:wiped) do
      password_digest { "*" }
    end
    trait(:admin) do
      is_admin { true }
      is_moderator { true }
    end
    trait(:moderator) do
      is_moderator { true }
    end
  end
end
