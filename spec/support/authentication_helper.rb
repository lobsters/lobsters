# typed: false

module AuthenticationHelper
  module ControllerHelper
    def stub_login_as user
      session[:u] = user.session_token
    end
  end

  module FeatureHelper
    def stub_login_as user
      # feature specs don't have access to the session store
      visit "/login"
      fill_in "E-mail or Username", with: user.email
      fill_in "Password", with: user.password
      click_button "Login"
    end
  end

  module RequestHelper
    def sign_in user
      post "/login", params: {email: user.email, password: user.password}
    end
  end
end
