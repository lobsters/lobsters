class SignupController < ApplicationController
  def index
    @title = "Signup"
    @new_user = User.new
  end

  def signup
    @new_user = User.new(params[:user])

    if @new_user.save
      session[:u] = @new_user.session_hash
      return redirect_to "/"
    else
      render :action => "index"
    end
  end

#	public function verify() {
#		if ($_SESSION["random_hash"] == "")
#			return $this->redirect_to("/signup?nocookies=1");
#
#		$this->page_title = "Signup";
#
#		$this->new_user = new User($this->params["user"]);
#		$this->new_user->username = $this->new_user->username;
#		if ($this->new_user->is_valid()) {
#			$error = false;
#			try {
#				$html = Utils::fetch_url("http://news.ycombinator.com/user?id="
#					. $this->new_user->username);
#			} catch (Exception $e) {
#				$error = true;
#				error_log("error fetching profile for "
#					. $this->new_user->username . ": " . $e->getMessage());
#			}
#
#			if ($error) {
#				$this->add_flash_error("Your Hacker News profile could "
#					. "not be fetched at this time.  Please try again "
#					. "later.");
#				return $this->render(array("action" => "index"));
#			} elseif (strpos($html, $_SESSION["random_hash"])) {
#				$this->new_user->save();
#
#				$this->add_flash_notice("Account created and verified. "
#					. "Welcome!");
#				$_SESSION["user_id"] = $this->new_user->id;
#                return $this->redirect_to("/");
#			} else {
#				$this->add_flash_error("Your Hacker News profile did not "
#					. "contain the string provided below.  Verify that "
#					. "you have cookies enabled and that your Hacker News "
#					. "profile has been saved after adding the string.");
#				return $this->render(array("action" => "index"));
#			}
#		} else
#			return $this->render(array("action" => "index"));
#	}
end
