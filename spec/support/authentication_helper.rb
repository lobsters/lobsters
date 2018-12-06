module AuthenticationHelper
  def stub_login_as user
    random_token = "abcdefg".split('').shuffle.join
    user.update_column(:session_token, random_token)
    allow_any_instance_of(ApplicationController).to receive(:session).and_return(u: random_token)
  end
end
