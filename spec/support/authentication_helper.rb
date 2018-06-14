module AuthenticationHelper
  def stub_login_as user
    user.update_column(:session_token, 'asdf')
    allow_any_instance_of(ApplicationController).to receive(:session).and_return(u: 'asdf')
  end
end
