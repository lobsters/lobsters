class StoriesController < ApplicationController
  before_filter :require_logged_in_user_or_400,
    :only => [ :upvote, :downvote, :unvote ]

  before_filter :require_logged_in_user, :only => [ :delete, :create, :edit,
    :fetch_url_title, :new ]

  def new
    @page_title = "Submit a New Story"

    @story = Story.new
    @story.story_type = "link"

    if !params[:url].blank?
      @story.url = params[:url]

      if !params[:title].blank?
        @story.title = params[:title]
      end
    end
  end

  def create
    @page_title = "Submit a New Story"

    @story = Story.new(params[:story])
    @story.user_id = @user.id

    if @story.save
	    Vote.vote_thusly_on_story_or_comment_for_user_because(1, @story.id,
        nil, @user.id, nil)

      return redirect_to @story.comments_url

    else
      if @story.already_posted_story?
        # consider it an upvote
        Vote.vote_thusly_on_story_or_comment_for_user_because(1,
          @story.already_posted_story.id, nil, @user.id, nil)

        return redirect_to @story.already_posted_story.comments_url
      end

      return render :action => "new"
    end
  end

  def delete
    if @user.is_admin?
      @story = Story.find_by_short_id(params[:id])
    else
      @story = Story.find_by_user_id_and_short_id(@user.id, params[:id])
    end

    if !@story
      flash[:error] = "Could not find story or you are not authorized to " <<
        "delete it."
      return redirect_to "/"
    end

    @story.is_expired = true
    @story.save

    redirect_to @story.comments_url
  end

#	public function edit() {
#		if (!$this->user) {
#			$this->add_flash_error("You must be logged in to edit a story.");
#			return $this->redirect_to("/login");
#		}
#
#		$this->story = Story::find_by_user_id_and_short_id($this->user->id,
#			$this->params["id"]);
#
#		if (!$this->story) {
#			$this->add_flash_error("Could not find story or you are not "
#				. "authorized to edit it.");
#			return $this->redirect_to("/");
#		}
#
#		$this->page_title = "Editing " . $this->story->title;
#	}
#
  def fetch_url_title
    begin
      s = Sponge.new
      s.timeout = 3
      text = s.fetch(params[:fetch_url], :get, nil, nil,
        { "User-agent" => "lobste.rs! via #{request.remote_ip}" }, 3)

      if m = text.match(/<\s*title\s*>([^<]+)<\/\s*title\s*>/i)
        return render :json => { :title => m[1] }
      else
        raise "no title found"
      end

    rescue => e
      return render :json => "error"
    end
  end

#	public function index() {
#		$this->items = Item::find("all");
#	}
#
#	public function manage() {
#		if (!$this->user) {
#			$this->add_flash_error("You must be logged in to manage your "
#				. "items.");
#			return $this->redirect_to("/login");
#		}
#
#		$this->page_title = "Manage Your Items";
#
#		$this->items = Item::column_sorter($this->params["_s"]);
#		$this->items->find("all",
#			array("conditions" => array("user_id = ?", $this->user->id),
#			"include" => array("user", "item_kind"),
#			"joins" => array("user")));
#	}
#
#	public function message() {
#		if (!$this->user) {
#			$this->add_flash_error("You must be logged in to edit an item.");
#			return $this->redirect_to("/login");
#		}
#
#		$this->show();
#
#		if ($this->new_message->update_attributes($this->params["message"])) {
#			$this->add_flash_notice("Your message has been sent.");
#			return $this->redirect_to(array("controller" => "items",
#				"action" => "show", "id" => $this->item->id));
#		} else {
#			return $this->render(array("action" => "items/show"));
#		}
#	}
#
 	def show
 		@story = Story.find_by_short_id!(params[:id])
 		
    @page_title = @story.title

 		@comments = @story.comments_in_order_for_user(@user ? @user.id : nil)
    @comment = Comment.new

 		if @user
 			if v = Vote.find_by_user_id_and_story_id(@user.id, @story.id)
 				@story.vote = v.vote
      end
 
 			@votes = Vote.comment_votes_by_user_for_story_hash(@user.id, @story.id)
 			@comments.each do |c|
 				if @votes[c.id]
 					c.vote = @votes[c.id]
        end
      end
 		end
  end

#	public function update() {
#		if (!$this->user) {
#			$this->add_flash_error("You must be logged in to edit an item.");
#			return $this->redirect_to("/login");
#		}
#
#		if ($this->user->is_admin)
#			$this->item = Item::find_by_id($this->params["id"]);
#		else
#			$this->item = Item::find_by_user_id_and_id($this->user->id,
#				$this->params["id"]);
#
#		if (!$this->item) {
#			$this->add_flash_error("Could not find item or you are not "
#				. "authorized to edit it.");
#			return $this->redirect_to("/");
#		}
#
#		$this->item->is_expired = false;
#		if ($this->item->update_attributes($this->params["item"])) {
#			$this->add_flash_notice("Successfully saved item changes.");
#			return $this->redirect_to(array("controller" => "items",
#				"action" => "show", "id" => $this->item->id));
#		} else
#			return $this->render(array("action" => "edit"));
#	}
#
  def unvote
    if !(story = Story.find_by_short_id(params[:story_id]))
      return render :text => "can't find story", :status => 400
    end

	  Vote.vote_thusly_on_story_or_comment_for_user_because(0, story.id,
      nil, @user.id, nil)

    render :text => "ok"
  end

  def upvote
    if !(story = Story.find_by_short_id(params[:story_id]))
      return render :text => "can't find story", :status => 400
    end

	  Vote.vote_thusly_on_story_or_comment_for_user_because(1, story.id,
      nil, @user.id, nil)

    render :text => "ok"
  end

  def downvote
    if !(story = Story.find_by_short_id(params[:story_id]))
      return render :text => "can't find story", :status => 400
    end
	  
    if !Vote::STORY_REASONS[params[:reason]]
      return render :text => "invalid reason", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story.id,
      nil, @user.id, params[:reason])

    render :text => "ok"
  end
end
