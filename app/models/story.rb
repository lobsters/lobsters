class Story < ActiveRecord::Base
	belongs_to :user
	has_many :taggings
  has_many :comments
  has_many :tags, :through => :taggings

  validates_length_of :title, :in => 3..150
  validates_length_of :description, :maximum => (64 * 1024)
  validates_format_of :url, :with => /\Ahttps?:\/\//i,
    :allow_blank => true
  validates_presence_of :user_id

  attr_accessible :url, :title, :description, :story_type, :tags_a

	# after this many minutes old, a story cannot be edited
	MAX_EDIT_MINS = 9999 # XXX 15

	attr_accessor :vote, :story_type, :already_posted_story
  attr_accessor :tags_to_add, :tags_to_delete

  after_save :deal_with_tags
  before_create :assign_short_id
  before_create :find_duplicate

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

  def find_duplicate
    if (s = Story.find_by_url(self.url)) &&
    (Time.now - s.created_at) < 30.days
      errors.add(:url, "has already been submitted recently")
      self.already_posted_story = s
    end
	end

  def deal_with_tags
    (self.tags_to_delete || []).each do |t|
      if t.is_a?(Tagging)
        t.destroy
      elsif t.is_a?(Tag)
        self.taggings.find_by_tag_id(t.id).try(:destroy)
      end
    end

    (self.tags_to_add || []).each do |t|
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
		parents = {}
    Comment.find_all_by_story_id(self.id).sort_by{|c| c.confidence }.each do |c|
      (parents[c.parent_comment_id.to_i] ||= []).push c
    end

    # top-down list of comments, regardless of indent level
    ordered = []

    recursor = lambda{|comment,level|
      if comment
        comment.indent_level = level
        ordered.push comment
      end

      # for each comment that is a child of this one, recurse with it
      (parents[comment ? comment.id : 0] || []).each do |child|
        recursor.call(child, level + 1)
      end
    }
    recursor.call(nil, 0)

    ordered
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

  def title=(t)
    # change unicode whitespace characters into real spaces
    self[:title] = t.strip
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
	
  def is_undeletable_by_user?(user)
		if !user || user.id != self.user_id
      return false
    end

    true
  end

	def update_comment_count!
		Keystore.put("story:#{self.id}:comment_count",
      Comment.where(:story_id => self.id).count)
	end

	def flag!
    Story.update_counters self.id, :flaggings => 1
  end
end
