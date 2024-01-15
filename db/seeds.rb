User.create!(
  username: "inactive-user",
  email: "inactive-user@aqora.io",
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
