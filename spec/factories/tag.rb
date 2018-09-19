# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    sequence(:tag) {|n| "tag-#{n}" }
    sequence(:description) {|n| "tag #{n}" }
  end
end
