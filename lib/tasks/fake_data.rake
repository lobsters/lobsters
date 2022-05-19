require 'faker'

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
        created_at: (User::NEW_USER_DAYS + 1).days.ago,
        karma: Random.rand(User::MIN_KARMA_TO_FLAG * 2),
        about: Faker::Lorem.sentence(word_count: 7),
        homepage: Faker::Internet.url,
        invited_by_user: User.select(&:can_invite?).sample,
      }
      create_args.merge!(is_admin: true) if i % 8 == 0
      users << User.create!(create_args)
      if i % 7 == 0
        users[i].grant_moderatorship_by_user!(mod)
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
    stories = []
    @stories_count.times do |i|
      user = users[Random.rand(@users_count-1)]
      title = Faker::Lorem.sentence(word_count: 3)
      category = categories[Random.rand(@categories_count)]
      tag_name = title.split(' ').first.downcase
      tag = Tag.find_by tag: tag_name
      tag ||= Tag.create! tag: tag_name, category: category
      url = Faker::Internet.url
      description = nil
      if i % 10 == 0
        description = Faker::Lorem.paragraphs(number: 3).join("\n\n")
        url = nil unless i % 7 == 0
      end
      create_args = {
        user: user,
        title: title,
        url: url,
        description: description,
        tags_a: [tag.tag],
      }
      stories << Story.create!(create_args)
    end

    # User-deleted stories. The stories are created here and deleted after
    # adding comments and other interactions.
    deleted_stories = []
    (@stories_count / 10).times do
      user = users[Random.rand(@users_count-1)]
      title = Faker::Lorem.sentence(word_count: 3)
      category = categories[Random.rand(@categories_count-1)]
      tag_name = title.split(' ').first.downcase
      tag = Tag.find_by tag: tag_name
      tag ||= Tag.create! tag: tag_name, category: category
      url = Faker::Internet.url
      create_args = {
        user: user,
        title: title,
        url: url,
        description: Faker::Lorem.paragraphs(number: 1),
        tags_a: [tag.tag],
        is_expired: true,
        editor: user,
      }
      stories << Story.create!(create_args)
      deleted_stories << story if i % 30 == 0
    end

    # User-saved stories
    (@stories_count / 10).times do
      user = users[Random.rand(@users_count-1)]
      story = stories[Random.rand(@stories_count - 1)]
      SavedStory.save_story_for_user(story.id, user.id)
    end

    # Comments
    comments = []
    stories.each do |x|
      Random.rand(1..3).times do |i|
        create_args = {
          user: users[Random.rand(@users_count-1)],
          comment: Faker::Lorem.sentence(word_count: Random.rand(30..50)),
          story_id: x.id,
        }
        comments << Comment.create!(create_args)

        # Replies to comments
        if i.odd?
          create_args = {
            user: x.user,
            comment: Faker::Lorem.sentence(word_count: Random.rand(30..50)),
            story_id: x.id,
            parent_comment_id: comments.last.id,
          }
          comments << Comment.create!(create_args)
        end
      end
    end

    # Comment Flags
    comments.each do |c|
      if Random.rand(100) > 95
        u = users[Random.rand(@users_count-1)]
        Vote.vote_thusly_on_story_or_comment_for_user_because(
          -1,
          c.story_id,
          c.id,
          u.id,
          Vote::COMMENT_REASONS.keys[Random.rand(Vote::COMMENT_REASONS.keys.length)]
        )
      end
    end

    # Story Flags
    stories.each do |s|
      if Random.rand(100) > 95
        u = users[Random.rand(@users_count-1)]
        Vote.vote_thusly_on_story_or_comment_for_user_because(
          -1,
          s.id,
          nil,
          u.id,
          Vote::STORY_REASONS.keys[Random.rand(Vote::STORY_REASONS.keys.length)]
        )
      end
    end

    # Hats
    hats = []
    (@users_count / 2).times do |i|
      suffixes = ["Developer", "Founder", "User", "Contributor", "Creator"]
      hat_wearer = users[i + 1]
      create_args = {
        user: hat_wearer,
        granted_by_user: users[0],
        hat: Faker::Lorem.word.capitalize + " " + suffixes[Random.rand(5)],
        link: Faker::Internet.url,
      }
      hat = Hat.create!(create_args)
      if i.odd?
        hat.doff_by_user_with_reason(hat_wearer, Faker::Lorem.sentence(word_count: 5))
      end
      hats << hat
    end

    ### Moderation ###

    # Comments (delete/undelete)
    comments.each_with_index do |comment, i|
      comment_mod = User.moderators.sample
      if i % 7 == 0
        comment.delete_for_user(comment_mod, Faker::Lorem.paragraphs(number: 1))
        comment.undelete_for_user(comment_mod) if i.even?
      end
    end

    # delete stories by submitter/mods
    deleted_stories.each do |story|
      if i.even?
        story.editor = story.user
      else
        story.editor = User.moderators.sample
        story.moderation_reason = Faker::Lorem.sentence(word_count: 5)
      end
      story.update(is_deleted: true)
    end

    # Hats
    2.times do
      hat = hats[Random.rand(hats.length - 1)]
      hat.doff_by_user_with_reason(User.moderators.sample,
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

    # Merging Stories
    5.times do
      story = stories[Random.rand(stories.length - 1)]
      second_story = stories[Random.rand(stories.length - 1)]
      while second_story == story
        second_story = stories[Random.rand(stories.length - 1)]
      end
      story.merged_story_id = second_story.id
      story.editing_from_suggestions = true
      story.moderation_reason = Faker::Lorem.sentence(word_count: 5)
      story.save
    end

    # Editing Stories
    5.times do
      story = stories[Random.rand(stories.length - 1)]
      story.title = Faker::Lorem.sentence(word_count: 4)
      story.editing_from_suggestions = true
      story.moderation_reason = Faker::Lorem.sentence(word_count: 5)
      story.save
    end

    # Deleting stories
    5.times do
      story = stories[Random.rand(stories.length - 1)]
      story.is_expired = true
      story.editing_from_suggestions = true
      story.moderation_reason = Faker::Lorem.sentence(word_count: 5)
      story.save
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

  FakeDataGenerator.new.generate
end
