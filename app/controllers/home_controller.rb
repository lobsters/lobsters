class HomeController < ApplicationController
	def index
		conds = [ "is_expired = 0 " ]

		if @user
			# exclude downvoted items
			conds[0] << "AND stories.id NOT IN (SELECT story_id FROM votes " <<
        "WHERE user_id = ? AND vote < 0) "
			conds.push @user.id
		end

    if @tag
      conds[0] << "AND taggings.tag_id = ?"
      conds.push @tag.id
      @stories = Story.find(:all, :conditions => conds,
        :include => [ :user, :taggings ], :joins => [ :user, :taggings ],
        :limit => 30)

      @title = @tag.description.blank?? @tag.tag : @tag.description
      @title_url = tag_url(@tag.tag)
    else
      @stories = Story.find(:all, :conditions => conds,
        :include => [ :user, :taggings ], :joins => [ :user ],
        :limit => 30)
    end

		if @user
			votes = Vote.votes_by_user_for_stories_hash(@user.id,
        @stories.map{|s| s.id })

      @stories.each do |s|
				if votes[s.id]
					s.vote = votes[s.id]
        end
      end
		end

    @stories.sort_by!{|s| s.hotness }

    render :action => "index"
	end

  def tagged
    if !(@tag = Tag.find_by_tag(params[:tag]))
      raise ActionController::RoutingError.new("tag not found")
    end

    index
  end
end
