class MessagesController < ApplicationController
#	static $verify = array(
#		array("method" => "post",
#			"only" => array("reply", "send"),
#			"redirect_to" => "/",
#		),
#	);
#
#	public function index() {
#		if (!$this->user) {
#			$this->add_flash_error("You must be logged in to read messages.");
#			return $this->redirect_to("/login");
#		}
#
#		$this->page_title = "Your Messages";
#
#		$this->incoming_messages =
#			Message::find_all_by_recipient_user_id($this->user->id,
#			array("order" => "created_at DESC"));
#
#		$this->sent_messages =
#			Message::find_all_by_author_user_id($this->user->id,
#			array("order" => "created_at DESC"));
#	}
#
#	public function show() {
#		if (!$this->user) {
#			$this->add_flash_error("You must be logged in to read messages.");
#			return $this->redirect_to("/login");
#		}
#
#		if (!($this->message = Message::find_by_random_hash($this->params["id"]))) {
#			$this->add_flash_error("Could not find message.");
#			return $this->redirect_to(array("controller" => "messages"));
#		}
#
#		if (!($this->message->recipient_user_id == $this->user->id ||
#		$this->message->author_user_id == $this->user->id)) {
#			$this->add_flash_error("Could not find message.");
#			return $this->redirect_to(array("controller" => "messages"));
#		}
#		
#		if ($this->message->recipient_user_id == $this->user->id &&
#		!$this->message->has_been_read) {
#			$this->message->has_been_read = true;
#			$this->message->save();
#		}
#
#		$this->page_title = "Message From "
#			. $this->message->author->username . " To "
#			. $this->message->recipient->username;
#
#		$this->reply = new Message;
#		$this->reply->author_user_id = $this->user->id;
#		$this->reply->recipient_user_id = $this->message->author_user_id;
#		$this->reply->subject = preg_match("/^re[: ]/i",
#			$this->message->subject) ? "" : "Re: " . $this->message->subject;
#	}
#
#	/* id is a message id */
#	public function reply() {
#		$this->show();
#
#		$this->page_title = "Message From "
#			. $this->message->author->username . " To "
#			. $this->message->recipient->username;
#
#		if ($this->reply->update_attributes($this->params["message"])) {
#			$this->add_flash_notice("Your reply has been sent.");
#			return $this->redirect_to(array("controller" => "messages"));
#		} else {
#			return $this->render(array("action" => "show"));
#		}
#	}
#
#	/* id is a username */
#	public function compose() {
#		if (!$this->user) {
#			$this->add_flash_error("You must be logged in to send messages.");
#			return $this->redirect_to("/login");
#		}
#
#		if (!($this->recipient_user =
#		User::find_by_username($this->params["id"]))) {
#			$this->add_flash_error("Could not find recipient user.");
#			return $this->redirect_to("/messages");
#		}
#
#		$this->page_title = "Compose Message To "
#			. $this->recipient_user->username;
#
#		$this->message = new Message;
#		$this->message->recipient_user_id = $this->recipient_user->id;
#		$this->message->author_user_id = $this->user->id;
#	}
#
#	public function send() {
#		$this->compose();
#
#		if ($this->message->update_attributes($this->params["message"])) {
#			$this->add_flash_notice("Your message has been sent.");
#			return $this->redirect_to(array("controller" => "messages"));
#		} else {
#			return $this->render(array("action" => "compose"));
#		}
#	}
end
