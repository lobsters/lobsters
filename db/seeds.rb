pwd = SecureRandom.base58
User.create!(
  username: "inactive-user",
  email: "inactive-user@aqora.io",
  password: pwd,
  password_confirmation: pwd
)

User.create(
  username: "stubbi",
  email: "jannes@aqora.io",
  password: "test",
  password_confirmation: "test",
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
categories_with_tags = {
  "Quantum Computing" => ["Superconducting Qubits", "Trapped Ions", "Neutral Atoms", "Quantum Dots", "Topological Qubits", "Photonic Quantum Computing", "Quantum Algorithms", "Error Correction", "Quantum Software", "Quantum Supremacy"],
  "Quantum Physics & Theory" => ["Quantum Entanglement", "Quantum Field Theory", "Nonlocality", "Quantum Gravity", "Bell Tests"],
  "Quantum Engineering & Materials" => ["Nanofabrication", "Quantum Dots", "Photonic Chips", "Topological Insulators", "Quantum Metamaterials"],
  "Quantum Applications" => ["Quantum Sensing", "Quantum Metrology", "Quantum Imaging", "Quantum Communications", "Quantum Simulation"],
  "Commercial Quantum Industry" => ["Quantum Startups", "Venture Capital", "Industry Partnerships", "Patent Landscape", "Market Analysis"],
  "Quantum Education & Outreach" => ["MOOCs", "University Programs", "Public Lectures", "Educational Initiatives", "Outreach Programs"],
  "Quantum Policy & Ethics" => ["Data Security", "Quantum-Ready Regulations", "Ethical AI", "Intellectual Property Rights", "Privacy Issues"],
  "Quantum Research & Collaboration" => ["International Collaborations", "Research Grants", "Laboratory Techniques", "Paper Discussions", "Experimental Setups"],
  "Quantum Information Science" => ["Quantum Cryptography", "QKD Protocols", "Information Theory", "Quantum Coding", "Entropy and Information"],
  "Quantum Technologies' Future" => ["Quantum Roadmaps", "Future Predictions", "Theoretical Breakthroughs", "Interdisciplinary Approaches", "Quantum AI"],
  "Quantum Networking & Communication" => ["Quantum Repeaters", "Network Protocols", "Satellite QKD", "Teleportation Experiments", "Quantum Internet"],
  "Events, Conferences & Workshops" => ["Upcoming Conferences", "Workshop Highlights", "Networking Events", "Virtual Seminars", "Community Meetups"]
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
