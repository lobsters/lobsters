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
  "Quantum_Computing" => ["Superconducting_Qubits", "Trapped_Ions", "Neutral_Atoms", "Quantum_Dots", "Topological_Qubits", "Photonics", "Quantum_Algorithms", "Error_Correction", "Quantum_Software", "Quantum_Supremacy"],
  "Quantum_Physics_Theory" => ["Quantum_Entanglement", "Quantum_Field_Theory", "Nonlocality", "Quantum_Gravity", "Bell_Tests"],
  "Quantum_Materials" => ["Nanofabrication", "Quantum_Dots", "Photonic_Chips", "Topological_Insulators", "Quantum_Metamaterials"],
  "Quantum_Applications" => ["Quantum_Sensing", "Quantum_Metrology", "Quantum_Imaging", "Quantum_Communications", "Quantum_Simulation"],
  "Quantum_Industry" => ["Quantum_Startups", "Venture_Capital", "Industry_Partnerships", "Patent_Landscape", "Market_Analysis"],
  "Quantum_Education" => ["MOOCs", "University_Programs", "Public_Lectures", "Educational_Initiatives", "Outreach_Programs"],
  "Quantum_Policy_Ethics" => ["Data_Security", "Quantum_Ready_Regulations", "Ethical_AI", "IP_Rights", "Privacy_Issues"],
  "Quantum_Research_Collab" => ["International_Collab", "Research_Grants", "Laboratory_Techniques", "Paper_Discussions", "Experimental_Setups"],
  "Quantum_Information" => ["Quantum_Cryptography", "QKD_Protocols", "Information_Theory", "Quantum_Coding", "Entropy_and_Information"],
  "Quantum_Technologies_Future" => ["Quantum_Roadmaps", "Future_Predictions", "Theoretical_Breakthroughs", "Interdisciplinary", "Quantum_AI"],
  "Quantum_Networking" => ["Quantum_Repeaters", "Network_Protocols", "Satellite_QKD", "Teleportation_Experiments", "Quantum_Internet"],
  "Events_Confs_Workshops" => ["Upcoming_Conferences", "Workshop_Highlights", "Networking_Events", "Virtual_Seminars", "Community_Meetups"]
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
