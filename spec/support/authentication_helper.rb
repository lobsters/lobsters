module AuthenticationHelper
  def stub_login_as user
    allow(User).to receive(:find_by).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:session).and_return(u: 'asdf')
  end
end
