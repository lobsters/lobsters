class VotesController < ApplicationController

	def stories_user_voted_on
		@stories_voted_on = @user.voted_stories.where("vote = '1'")
	end

end
