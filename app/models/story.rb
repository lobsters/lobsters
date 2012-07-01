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
  MAX_EDIT_MINS = 30

  attr_accessor :vote, :story_type, :already_posted_story, :fetched_content
  attr_accessor :new_tags, :tags_to_add, :tags_to_delete

  after_save :deal_with_tags
  before_create :assign_short_id
  after_create :mark_submitter

  validate do
    if self.url.present?
      # URI.parse is not very lenient, so we can't use it

      if self.url.match(/\Ahttps?:\/\/([^\.]+\.)+[a-z]+(\/|\z)/)
        if (s = Story.find_by_url(self.url)) &&
        (Time.now - s.created_at) < 30.days
          errors.add(:url, "has already been submitted recently")
          self.already_posted_story = s
        end
      else
        errors.add(:url, "is not valid")
      end
    elsif self.description.to_s.strip == ""
      errors.add(:description, "must contain text if no URL posted")
    end

    if !(self.new_tags || []).reject{|t| t.to_s.strip == "" }.any?
      errors.add(:base, "Must have at least one tag.  If no tags apply to " +
        "your content, it probably doesn't belong here.")
    end
  end

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

  def mark_submitter
    Keystore.increment_value_for("user:#{self.user_id}:stories_submitted")
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

  def comments_url(root_url = "/")
    root_url + "s/#{self.short_id}/#{self.title_as_url}"
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

  def fetched_title(for_remote_ip = nil)
    doc = Nokogiri::HTML(fetched_content(for_remote_ip).to_s)
    return doc.at_css("title").text  
  end

  def fetched_content(for_remote_ip = nil)
    return @fetched_content if @fetched_content

    begin
      s = Sponge.new
      s.timeout = 3
      @fetched_content = s.fetch(self.url, :get, nil, nil,
        { "User-agent" => "lobste.rs! for #{for_remote_ip}" }, 3)
    rescue
    end

    @fetched_content
  end

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
    self.new_tags = new_tags

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
    while u.match(/__/)
      u.gsub!("__", "_")
    end
    u
  end

  def url_or_comments_url(root_url = "/")
    self.url.blank? ? self.comments_url(root_url) : self.url
  end

  def is_editable_by_user?(user)
    if !user || user.id != self.user_id
      return false
    end

    (Time.now.to_i - self.created_at.to_i < (60 * MAX_EDIT_MINS))
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
end
