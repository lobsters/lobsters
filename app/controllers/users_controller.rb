class UsersController < ApplicationController
#	function settings() {
#		if (!$this->user) {
#			$this->add_flash_error("You must be logged in to edit your "
#				. "settings.");
#			return $this->redirect_to("/login");
#		}
#
#		$this->page_title = "Edit Settings";
#
#		$this->showing_user = clone $this->user;
#	}
#
#	function show() {
#		if (!($this->showing_user = User::find_by_username($this->params["id"]))) {
#			$this->add_flash_error("Could not find user.");
#			return $this->redirect_to("/");
#		}
#
#		$this->page_title = "User " . $this->showing_user->username;
#
#		if (!$this->params["_s"])
#			$this->params["_s"] = NULL;
#
#		$this->items = Item::column_sorter($this->params["_s"]);
#		$this->items->find("all",
#			array("conditions" => array("user_id = ? AND is_expired = 0",
#				$this->showing_user->id),
#			"include" => array("user", "item_kind"),
#			"joins" => array("user")));
#	}
#
#	function update() {
#		if (!$this->user) {
#			$this->add_flash_error("You must be logged in to edit your "
#				. "settings.");
#			return $this->redirect_to("/login");
#		}
#
#		$this->page_title = "Edit Settings";
#
#		$this->showing_user = clone $this->user;
#
#		if ($this->showing_user->update_attributes($this->params["user"])) {
#			$this->add_flash_notice("Your settings have been updated.");
#			return $this->redirect_to(array("controller" => "users",
#				"action" => "settings"));
#		} else
#			return $this->render(array("action" => "settings"));
#	}
end
