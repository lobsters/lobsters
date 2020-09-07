class FakeDataGenerator
  def initialize(users_count, stories_count, categories_count)
    @users_count = users_count
    @stories_count = stories_count
    @categories_count = categories_count
  end

  def generate
    # Users and Moderators
    users = []
    0.upto(@users_count).each do |i|
      mod = User.moderators.sample
      name = Faker::Name.name
      password = Faker::Internet.password
      create_args = {
        email: Faker::Internet.email(name: name),
        password: password,
        password_confirmation: password,
        username: Faker::Internet.user_name(specifier: name, separators: %w(_)),
        created_at: User::NEW_USER_DAYS.days.ago,
        invited_by_user: User.select(&:can_invite?).sample,
      }
      users << User.create!(create_args)
      if i % 7 == 0
        users[i].grant_moderatorship_by_user!(mod)
      end
      if i % 3 == 0
        users[i].enable_invite_by_user!(mod)
      end
      if i % 6 == 0
        users[i].disable_invite_by_user_for_reason!(mod, Faker::Lorem.sentence(word_count: 5))
      end
    end

    # Categories
    categories = []
    @categories_count.times do
      cat = Faker::Lorem.word.capitalize
      categories << Category.create!(category: cat) unless Category.find_by(category: cat)
    end

    # Stories
    @stories_count.times do |i|
      user = users[Random.rand(@users_count-1)]
      title = Faker::Lorem.sentence(word_count: 3)
      category = categories[Random.rand(@categories_count)]
      tag_name = title.split(' ').first.downcase
      tag = Tag.find_by tag: tag_name
      tag ||= Tag.create! tag: tag_name, category: category
      url = Faker::Internet.url
      description = nil
      if i.odd?
        description = Faker::Lorem.paragraphs(number: 3).join("\n\n")
        url = nil unless i % 7 == 0
      end
      Story.create! user: user,
        title: title,
        url: url,
        description: description,
        tags_a: [tag.tag]
    end

    # User-deleted stories
    (@stories_count / 10).times do
      user = users[Random.rand(@users_count-1)]
      title = Faker::Lorem.sentence(word_count: 3)
      category = categories[Random.rand(@categories_count-1)]
      tag_name = title.split(' ').first.downcase
      tag = Tag.find_by tag: tag_name
      tag ||= Tag.create! tag: tag_name, category: category
      Story.create! user: user,
        title: title,
        tags_a: [tag.tag],
        description: Faker::Lorem.paragraphs(number: 1),
        is_expired: true,
        editor: user
    end

    # User-saved stories
    (@stories_count / 10).times do
      user = users[Random.rand(@users_count-1)]
      story = Story.find(Random.rand(@stories_count-1))
      SavedStory.save_story_for_user(story.id, user.id)
    end

    # Comments
    Story.all.each do |x|
      Random.rand(1..3).times do |i|
        c = Comment.create! user: users[Random.rand(@users_count-1)],
          comment: Faker::Lorem.sentence(word_count: Random.rand(30..50)),
          story_id: x.id
        # Replies to comments
        if i.odd?
          Comment.create! user: x.user,
            comment: Faker::Lorem.sentence(word_count: Random.rand(30..50)),
            story_id: x.id,
            parent_comment_id: c.id
        end
      end
    end

    # Hats
    (@users_count / 2).times do |i|
      suffixes = ["Developer", "Founder", "User", "Contributor", "Creator"]
      hat_wearer = users[i + 1]
      hat = Hat.create! user: hat_wearer,
                granted_by_user: users[0],
                hat: Faker::Lorem.word.capitalize + " " + suffixes[Random.rand(5)],
                link: Faker::Internet.url
      if i.odd?
        hat.doff_by_user_with_reason(hat_wearer, Faker::Lorem.sentence(word_count: 5))
      end
    end

    ### Moderation ###

    # Comments (delete/undelete)
    Comment.all.each_with_index do |comment, i|
      comment_mod = User.moderators.sample
      if i % 7 == 0
        comment.delete_for_user(comment_mod, Faker::Lorem.paragraphs(number: 1))
        comment.undelete_for_user(comment_mod) if i.even?
      end
    end

    # Hats
    Hat.all.sample(2).each do |hat|
      hat.destroy_by_user_with_reason(User.moderators.sample,
                                      Faker::Lorem.sentence(word_count: 5))
    end

    # Users, don't delete inactive-user or test
    User.where('id > 2').sample(2).each_with_index do |user, i|
      user.ban_by_user_for_reason!(User.moderators.sample,
                                   Faker::Lorem.sentence(word_count: 5))
      if i.even?
        user.unban_by_user!(User.moderators.sample)
      end
    end
  end
end

desc 'Generates fake data for testing purposes'
task fake_data: :environment do
  fail "Refusing to add fake-data to a non-development environment" unless Rails.env.development?

  record_count = User.count + Tag.count + Story.count + Comment.count
  if record_count > 3 # more than would be created by db:seed
    warn "Database has #{record_count} records, are you sure you want to add more? [y to continue]"
    fail "Cancelled" if STDIN.gets.chomp != 'y'
  end

  FakeDataGenerator.new(20, 200, 5).generate
end
