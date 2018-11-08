FactoryBot.define do
  factory :user do
    sequence(:email) {|n| "user-#{n}@example.com" }
    sequence(:username) {|n| "username#{n}" }
    password { "blah blah" }
    password_confirmation(&:password)
    trait(:banned) do
      transient do
        banner { nil }
      end
      banned_at { Time.current }
      banned_reason { "some reason" }
      banned_by_user_id { banner && banner.id }
    end
    trait(:noinvite) do
      transient do
        disabler { nil }
      end
      disabled_invite_at { Time.current }
      disabled_invite_reason { "some reason" }
      disabled_invite_by_user_id { disabler && disabler.id }
    end
    trait(:inactive) do
      username { 'inactive-user' }
      to_create {|user| user.save(validate: false) }
    end
    trait(:deleted) do
      deleted_at { Time.current }
    end
    # users who were banned/deleted before a server move
    # you must also add banned/deleted trait with this
    trait(:wiped) do
      password_digest { '*' }
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
