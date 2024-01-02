pwd = SecureRandom.base58
User.create!(
  username: "inactive-user",
  email: "inactive-user@aqora.io",
  password: pwd,
  password_confirmation: pwd
)

User.create(
  username: "quantumnews",
  email: "quantumnews@aqora.io",
  password: ENV.fetch('ADMIN_PASSWORD', 'quantumnews'),
  password_confirmation: ENV.fetch('ADMIN_PASSWORD', 'quantumnews'),
  is_admin: true,
  is_moderator: true,
  karma: [
    User::MIN_KARMA_TO_SUGGEST,
    User::MIN_KARMA_TO_FLAG,
    User::MIN_KARMA_TO_SUBMIT_STORIES,
    User::MIN_KARMA_FOR_INVITATION_REQUESTS
  ].max,
  created_at: User::NEW_USER_DAYS.days.ago
)

# Define categories and their corresponding tags
# https://lobste.rs/tags
categories_with_tags = {
  "format" => ["ask", "audio", "book", "pdf", "show", "slides", "transcript", "video"],
  "quantumnews" => ["announce", "interview", "meta"],
}

# Iterate over the categories and their tags
categories_with_tags.each do |category_name, tags|
  c = Category.create!(category: category_name)

  tags.each do |tag_name|
    Tag.create(category: c, tag: tag_name)
  end
end

puts "created:"
puts "  * an admin with username/password of test/test"
puts "  * inactive-user for disowned comments by deleted users"
puts "Categories and corresponding tags have been created."
