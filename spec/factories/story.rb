Tag.destroy_all
Tag.create!([
  { tag: "tag1" },
  { tag: "tag2" },
])

FactoryBot.define do
  factory :story do
    association(:user)
    sequence(:title) {|n| "story title #{n}" }
    sequence(:url) {|n| "http://example.com/#{n}" }
    tags_a ["tag1", "tag2"]
  end
end
