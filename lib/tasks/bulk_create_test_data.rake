desc "create users"
task :bulk_create_users, [:count] => :environment do |t, args|
  user_count = args[:count].to_i

  1.upto(user_count).map do |i|
    name = "#{Faker::Name.name}##{i}"
    User.create!({
      email: Faker::Internet.email(name: name),
      password: "test",
      password_confirmation: "test",
      username: Faker::Internet.user_name(specifier: name, separators: %w[_])[..23],
      created_at: (User::NEW_USER_DAYS + 1).days.ago,
      karma: Random.rand(User::MIN_KARMA_TO_FLAG * 2),
      about: Faker::Lorem.sentence(word_count: 7),
      homepage: Faker::Internet.url,
      invited_by_user: User.select(&:can_invite?).sample
    })
  end
end

desc "create categories"
task :bulk_create_categories, [:count] => :environment do |t, args|
  category_count = args[:count].to_i

  1.upto(category_count).map do |i|
    Category.create!({
      category: "#{Faker::Lorem.word.capitalize}_#{i}" # Add a number since I've encountered duplicates in even a small sample size
    })
  end
end

desc "create tags"
task :bulk_create_tags, [:count] => :environment do |t, args|
  categories = Category.all
  tag_count = args[:count].to_i

  1.upto(tag_count).map do |i|
    Tag.create!({
      tag: "tag_#{i}",
      category: categories.sample,
      description: Faker::Lorem.sentence(word_count: Random.rand(2..15))[...100]
    })
  end
end

# https://gist.github.com/searls/2859ad7e8941872edb9561eb965b7c76
def lorem_paragraphs(paragraphs = (1..4), sentences = (1..10), words = (3..20))
  rand(paragraphs).times.map {
    rand(sentences).times.map {
      Faker::Lorem.sentence(word_count: rand(words))
    }.join(" ")
  }.join("\n\n")
end

def markdown_paragraphs
  lorem_paragraphs.split("\n\n").map { |sentence|
    sentence.split(" ").map { |word|
      if rand(100) < 1
        "_#{word}_"
      elsif rand(100) < 2
        "[#{word}](http://example.com/#{word})"
      else
        word
      end
    }.join(" ")
  }.join("\n\n")
end

desc "create stories"
task :bulk_create_stories, [:count] => :environment do |t, args|
  users = User.all
  tags = Tag.all
  story_count = args[:count].to_i

  1.upto(story_count).map do |i|
    Story.create!({
      user: users.sample,
      title: Faker::Lorem.sentence(word_count: 3),
      url: "#{Faker::Internet.url}#{i}", # bypass limit on reposting same url within 30 days
      description: markdown_paragraphs,
      tags: [tags.sample]
    })
  end
end

desc "create story_texts"
task bulk_create_story_texts: :environment do |t, args|
  Story.where.missing(:story_text).map do |story|
    StoryText.create!({
      id: story.id,
      title: story.title,
      description: story.description,
      body: markdown_paragraphs
    })
  end
end

desc "create comments"
task :bulk_create_comments, [:count] => :environment do |t, args|
  users = User.all
  stories = Story.all

  comment_count = args[:count].to_i
  percent_of_top_level_comments = 0.3

  replies_to_stories_count = (percent_of_top_level_comments * comment_count).floor
  replies_to_comments_count = comment_count - replies_to_stories_count

  all_comments = []

  1.upto(replies_to_stories_count).each do |i|
    all_comments << Comment.create!({
      user: users.sample,
      comment: markdown_paragraphs,
      story_id: stories.sample.id
    })
  end

  1.upto(replies_to_comments_count).each do |i|
    comment_to_reply_to = all_comments.sample

    all_comments << Comment.create!({
      user: users.sample,
      comment: markdown_paragraphs,
      story_id: comment_to_reply_to.story_id,
      parent_comment_id: comment_to_reply_to.id
    })
  end
end

desc "create votes"
task :bulk_create_votes, [:count_for_stories, :count_for_comments] => :environment do |t, args|
  users = User.all
  stories = Story.all
  comments = Comment.all

  story_vote_count = args[:count_for_stories].to_i
  comment_vote_count = args[:count_for_comments].to_i

  comment_vote_count_per_user = comment_vote_count.fdiv(users.count).ceil
  story_vote_count_per_user = story_vote_count.fdiv(users.count).ceil

  # There's a chance a user could sample stories & comments they've already upvoted, but the chances are low and the voting method handles this by ignoring the vote.
  # We might have slightly less votes as a result but not enough to make a difference.

  users.each do |user|
    stories.sample(story_vote_count_per_user).each do |story|
      new_vote = 1
      story_id = story.id
      comment_id = nil
      user_id = user.id
      reason = nil

      Vote.vote_thusly_on_story_or_comment_for_user_because(new_vote, story_id, comment_id, user_id, reason)
    end
  end

  users.each do |user|
    comments.sample(comment_vote_count_per_user).each do |comment|
      new_vote = 1
      story_id = comment.story_id
      comment_id = comment.id
      user_id = user.id
      reason = nil

      Vote.vote_thusly_on_story_or_comment_for_user_because(new_vote, story_id, comment_id, user_id, reason)
    end
  end
end
