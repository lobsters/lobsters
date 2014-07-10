class FakeDataGenerator
  def initialize(users_count, stories_count)
    @users_count = users_count
    @stories_count = stories_count
  end

  def generate
    users = 0.upto(@users_count).map do |i|
      name = Faker::Name.name
      password = Faker::Internet.password
      user_name = Faker::Internet.user_name(name, %w(_))
      User.create! email: Faker::Internet.email(name),
        password: password,
        password_confirmation: password,
        username: user_name
    end

    @stories_count.times do
      user = users[Random.rand(users.length-1)]
      title = Faker::Lorem.sentence(3)
      tag = Tag.find_or_create_by! tag: title.split(' ').first.downcase
      Story.create! user: user, title: title, url: Faker::Internet.url, tags_a: [tag.tag]
    end
  end
end

desc 'Generates fake data for testing purposes'
task fake_data: :environment do
  fail "It's not intended to be run outside development environment" unless Rails.env.development?
  unless (User.count + Tag.count + Story.count) == 0
    fail "Please ensure that you're running it on clean database because it will destroy all data"
  end

  User.destroy_all
  Tag.destroy_all
  Story.destroy_all

  FakeDataGenerator.new(10, 1_000).generate
end
