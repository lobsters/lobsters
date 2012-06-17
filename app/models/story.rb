class Story < ActiveRecord::Base
	belongs_to :user
	has_many :taggings
  has_many :comments
  has_many :tags, :through => :taggings

  attr_accessible :url, :title, :description, :story_type, :tags_a

	# after this many minutes old, a story cannot be edited
	MAX_EDIT_MINS = 9999 # XXX 15

	attr_accessor :vote, :story_type, :already_posted_story
  attr_accessor :tags_to_add, :tags_to_delete

  after_save :deal_with_tags
  before_create :assign_short_id

	def assign_short_id
		(1...10).each do |tries|
			if tries == 10
				raise "too many hash collisions"
      end

			self.short_id = Utils.random_str(6)
			if !Story.find_by_short_id(self.short_id)
				break
      end
		end
  end

  def deal_with_tags
    self.tags_to_delete.each do |t|
      if t.is_a?(Tagging)
        t.destroy
      elsif t.is_a?(Tag)
        self.taggings.find_by_tag_id(t.id).try(:destroy)
      end
    end

    self.tags_to_add.each do |t|
      if t.is_a?(Tag)
        tg = Tagging.new
        tg.tag_id = t.id
        tg.story_id = self.id
        tg.save
      end
    end

    self.tags_to_delete = []
    self.tags_to_add = []
  end

	def comments_in_order_for_user(user_id)
		Comment.find_all_by_story_id(self.id)
    # TODO
	end

	def comments_url
		"/p/#{self.short_id}/#{self.title_as_url}"
  end

	@_comment_count = nil
	def comment_count
		@_comment_count ||=
      Keystore.value_for("story:#{self.id}:comment_count").to_i
	end

	def domain
		if self.url.blank?
			nil
		else
			pu = URI.parse(self.url)
			pu.host.gsub(/^www\d*\./, "")
    end
  end

  UP_RANGE = 400
  DOWN_RANGE = 100

  def hotness
    score = upvotes - downvotes
    order = Math.log([ score.abs, 1 ].max, 10)
    if score > 0
      sign = 1
    elsif score < 0
      sign = -1
    else
      sign = 0
    end

    seconds = self.created_at.to_i - 398995200
    return -(order + (sign * (seconds.to_f / 45000))).round(7)
  end

	def linkified_text
		Markdowner.markdown(self.description)
  end

  def tags_a
    tags.map{|t| t.tag }
  end
  def tags_a=(new_tags)
    self.tags_to_delete = []
    self.tags_to_add = []

    self.tags.each do |tag|
      if !new_tags.include?(tag.tag)
        self.tags_to_delete.push tag
      end
    end

    new_tags.each do |tag|
      if tag.to_s != "" && !self.tags.map{|t| t.tag }.include?(tag)
        if t = Tag.find_by_tag(tag)
          self.tags_to_add.push t
        end
      end
    end
  end

	def title_as_url
		u = self.title.downcase.gsub(/[^a-z0-9_-]/, "_")
		while self.title.match(/__/)
			self.title.gsub!("__", "_")
    end

		u
	end

	def url_or_comments_url
		self.url.blank? ? self.comments_url : self.url
	end

	def is_editable_by_user?(user)
		if !user || user.id != self.user_id
      return false
    end

		true #(Time.now.to_i - self.created_at.to_i < (60 * Story::MAX_EDIT_MINS))
	end

	def update_comment_count!
		Keystore.put("story:#{self.id}:comment_count",
      Comment.count_by_story_id(self.id))
	end

	def validate
		if self.title.blank?
			self.errors.add(:title, "cannot be blank.")
    end

#		if (strlen($this->title) > 100)
#			$this->errors->add("title", "cannot be longer than 100 "
#				. "characters.");
#
#		if ($this->story_type == "text") {
#			$this->url = null;
#
#			if (trim($this->description) == "")
#				$this->errors->add("description", "cannot be blank.");
#			elseif (strlen($this->description) > (64 * 1024))
#				$this->errors->add("description", "is too long.");
#		}
#		else {
#			$this->description = null;
#
#			if (!preg_match("/^https?:\/\//i", $this->url))
#				$this->errors->add("url", "does not look valid.");
#
#			$now = new DateTime("now");
#			if (($old = Story::find_by_url($this->url)) &&
#			($old->created_at->diff($now)->format("%s") < (60 * 60 * 30))) {
#				$this->errors->add("url", "has already been posted in the "
#					. "last 30 days.");
#				$this->already_posted_story = $old;
#			}
#		}
#
#		if (empty($this->user_id))
#			$this->errors->add("user_id", "cannot be blank.");
	end

	def flag!
    Story.update_counters self.id, :flaggings => 1
  end
end
