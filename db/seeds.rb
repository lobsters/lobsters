User.create(:username => "test", :email => "test@example.com", :password => "test", :password_confirmation => "test", :is_admin => true, :is_moderator => true)
puts "created user: test, password: test"
Tag.create(:tag => "test")
puts "created tag: test"