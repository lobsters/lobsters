class Comment < ActiveRecord::Base
	belongs_to :user
  belongs_to :story

  attr_accessible :comment

  attr_accessor :parent_comment_short_id, :vote

	def before_create
		(1...10).each do |tries|
			if tries == 10
				raise "too many hash collisions"
      end

			if !Comment.find_by_short_id(self.short_id = Utils.random_str(6))
				break
      end
		end

		self.upvotes = 1
	end

	def after_create
		self.vote_for_user(self.user_id, 1)
		self.story.upvote_comment_count!
	end

	def after_destroy
		self.story.update_comment_count!
	end

	def score
		self.upvotes - self.downvotes
  end

	def linkified_comment
		Markdowner.markdown(self.comment)
	end

	def validate
		self.comment.strip == "" &&
			self.errors.add(:comment, "cannot be blank.")

		self.user_id.blank? &&
      self.errors.add(:user_id, "cannot be blank.")

		self.story_id.blank? &&
		  self.errors.add(:story_id, "cannot be blank.")
	end

	def upvote!(amount = 1)
		Story.update_counters self.id, :upvotes => amount
	end

	def flag!
    Story.update_counters self.id, :flaggings => 1
  end
end
