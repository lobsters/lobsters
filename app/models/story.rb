class Story < ActiveRecord::Base
  belongs_to :user
  has_many :taggings
  has_many :comments
  has_many :tags, :through => :taggings

  validates_length_of :title, :in => 3..150
  validates_length_of :description, :maximum => (64 * 1024)
  validates_presence_of :user_id

  # after this many minutes old, a story cannot be edited
  MAX_EDIT_MINS = 30

  attr_accessor :_comment_count
  attr_accessor :vote, :already_posted_story, :fetched_content, :previewing
  attr_accessor :new_tags, :tags_to_add, :tags_to_delete
  attr_accessor :editor_user_id, :moderation_reason

  attr_accessible :title, :description, :tags_a, :moderation_reason

  before_create :assign_short_id
  before_save :log_moderation
  after_create :mark_submitter, :deliver_mention_notifications
  after_save :deal_with_tags
  
  define_index do
    indexes url
    indexes title
    indexes description
    indexes user.username, :as => :author
    indexes tags(:tag), :as => :tags

    has created_at, :sortable => true
    has hotness, is_expired
    has "(upvotes - downvotes)", :as => :score, :type => :integer,
      :sortable => true

    set_property :field_weights => {
      :title => 10,
      :tags => 5,
    }

    where "is_expired = 0"
  end

  validate do
    if self.url.present?
      # URI.parse is not very lenient, so we can't use it

      if self.url.match(/\Ahttps?:\/\/([^\.]+\.)+[a-z]+(\/|\z)/)
        if self.new_record? && (s = Story.find_recent_similar_by_url(self.url))
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

  def self.find_recent_similar_by_url(url)
    urls = [ url.to_s ]
    urls2 = [ url.to_s ]

    # https
    urls.each do |u|
      urls2.push u.gsub(/^http:\/\//i, "https://")
      urls2.push u.gsub(/^https:\/\//i, "http://")
    end
    urls = urls2.clone

    # trailing slash
    urls.each do |u|
      urls2.push u.gsub(/\/+\z/, "")
      urls2.push (u + "/")
    end
    urls = urls2.clone

    # www prefix
    urls.each do |u|
      urls2.push u.gsub(/^(https?:\/\/)www\d*\./i) {|_| $1 }
      urls2.push u.gsub(/^(https?:\/\/)/i) {|_| "#{$1}www." }
    end
    urls = urls2.clone

    conds = [ "created_at >= ? AND (", (Time.now - 30.days) ]
    urls.uniq.each_with_index do |u,x|
      conds[0] << (x == 0 ? "" : " OR ") << "url = ?"
      conds.push u
    end
    conds[0] << ")"

    if s = Story.find(:first, :conditions => conds)
      return s
    end

    false
  end

  def assign_short_id
    10.times do |try|
      if try == 10
        raise "too many hash collisions"
      end

      self.short_id = Utils.random_str(6).downcase

      if !Story.find_by_short_id(self.short_id)
        break
      end
    end
  end

  def log_moderation
    if self.new_record? || self.editor_user_id == self.user_id
      return
    end

    m = Moderation.new
    m.moderator_user_id = self.editor_user_id
    m.story_id = self.id

    if self.changes["is_expired"] && self.is_expired?
      m.action = "deleted story"
    elsif self.changes["is_expired"] && !self.is_expired?
      m.action = "undeleted story"
    else
      actions = self.changes.map{|k,v| "changed #{k} from #{v[0].inspect} " <<
        "to #{v[1].inspect}" }

      if (old_tags = self.tags.map{|t| t.tag }) != self.tags_a
        actions.push "changed tags from \"#{old_tags.join(", ")}\" to " <<
          "\"#{self.tags_a.join(", ")}\""
      end

      m.action = actions.join(", ")
    end

    m.reason = self.moderation_reason
    m.save

    self.is_moderated = true
  end

  def give_upvote_or_downvote_and_recalculate_hotness!(upvote, downvote)
    self.upvotes += upvote.to_i
    self.downvotes += downvote.to_i

    Story.connection.execute("UPDATE #{Story.table_name} SET " <<
      "upvotes = COALESCE(upvotes, 0) + #{upvote.to_i}, " <<
      "downvotes = COALESCE(downvotes, 0) + #{downvote.to_i}, " <<
      "hotness = '#{self.calculated_hotness}' WHERE id = #{self.id.to_i}")
  end

  def mark_submitter
    Keystore.increment_value_for("user:#{self.user_id}:stories_submitted")
  end

  def deliver_mention_notifications
    self.description.scan(/\B\@([\w\-]+)/).flatten.uniq.each do |mention|
      if u = User.find_by_username(mention)
        begin
          if u.email_mentions?
            EmailReply.mention(self, u).deliver
          end

          if u.pushover_mentions? && u.pushover_user_key.present?
            Pushover.push(u.pushover_user_key, u.pushover_device, {
              :title => "Lobsters mention by #{self.user.username} on " <<
                self.title,
              :message => self.description,
              :url => self.url,
              :url_title => "Reply to #{self.user.username}",
            })
          end
        rescue => e
          Rails.logger.error "failed to deliver mention notification to " <<
            "#{u.username}: #{e.message}"
        end
      end
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

  def comments_url
    "#{short_id_url}/#{self.title_as_url}"
  end
  
  def short_id_url
    Rails.application.routes.url_helpers.root_url + "s/#{self.short_id}"
  end

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
    if doc
      return doc.at_css("title").try(:text)
    else
      return ""
    end
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

  def calculated_hotness
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

    # XXX: while we're slow, allow a window of 36 hours.  as the site grows,
    # shrink this down to 12 or so.
    window = 60 * 60 * 36

    return -(order + (sign * (seconds.to_f / window))).round(7)
  end

  def generated_markeddown_description
    Markdowner.to_html(self.description)
  end

  def description=(desc)
    self[:description] = desc.to_s.rstrip
    self.markeddown_description = self.generated_markeddown_description
  end

  @_tags_a = []
  def tags_a
    @_tags_a ||= tags.map{|t| t.tag }
  end

  def tags_a=(new_tags)
    self.tags_to_delete = []
    self.tags_to_add = []
    self.new_tags = new_tags.reject{|t| t.blank? }

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

    @_tags_a = self.new_tags
  end

  def url=(u)
    # strip out stupid google analytics parameters
    if u && (m = u.match(/\A([^\?]+)\?(.+)\z/))
      params = m[2].split("&")
      params.reject!{|p|
        p.match(/^utm_(source|medium|campaign|term|content)=/) }

      u = m[1] << (params.any?? "?" << params.join("&") : "")
    end

    self[:url] = u
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
    u.gsub(/^_+/, "").gsub(/_+$/, "")
  end

  def url_or_comments_url
    self.url.blank? ? self.comments_url : self.url
  end

  def is_editable_by_user?(user)
    if user && user.is_moderator?
      return true
    elsif user && user.id == self.user_id
      if self.is_moderated?
        return false
      else
        return (Time.now.to_i - self.created_at.to_i < (60 * MAX_EDIT_MINS))
      end
    else
      return false
    end
  end
  
  def is_undeletable_by_user?(user)
    if user && user.is_moderator?
      return true
    elsif user && user.id == self.user_id && !self.is_moderated?
      return true
    else
      return false
    end
  end

  def can_be_seen_by_user?(user)
    if is_gone? && !(user && (user.is_moderator? || user.id == self.user_id))
      return false
    end

    true
  end

  def is_gone?
    is_expired?
  end

  def update_comment_count!
    Keystore.put("story:#{self.id}:comment_count",
      Comment.where(:story_id => self.id, :is_deleted => 0).count)
  end
end
