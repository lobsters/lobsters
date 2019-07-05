module AuthenticationHelper
  module ControllerHelper
    def stub_login_as user
      random_token = ::AuthenticationHelper::common_setup user
      session[:u] = random_token
    end
  end

  module FeatureHelper
    def stub_login_as user
      random_token = ::AuthenticationHelper::common_setup user
      # feature specs don't have access to the session store
      visit '/login'
      fill_in 'E-mail or Username:', with: user.email
      fill_in 'Password:', with: user.password
      click_button 'Login'
    end
  end

  private

  def self.common_setup user
    random_token = "abcdefg".split('').shuffle.join
    user.update_column(:session_token, random_token)
    random_token
  end
end
