class Story < ActiveRecord::Base
  belongs_to :user
  has_many :taggings,
    :include => :tag,
    :autosave => true
  has_many :comments
  has_many :tags, :through => :taggings

  validates_length_of :title, :in => 3..150
  validates_length_of :description, :maximum => (64 * 1024)
  validates_presence_of :user_id

  # after this many minutes old, a story cannot be edited
  MAX_EDIT_MINS = 30

  attr_accessor :_comment_count
  attr_accessor :vote, :already_posted_story, :fetched_content, :previewing
  attr_accessor :editor_user_id, :moderation_reason

  attr_accessible :title, :description, :tags_a, :moderation_reason

  before_validation :assign_short_id,
    :on => :create
  before_save :log_moderation
  after_create :mark_submitter

  define_index do
    indexes url
    indexes title
    indexes description
    indexes user.username, :as => :author
    indexes tags(:tag), :as => :tags

    has created_at, :sortable => true
    has hotness, is_expired
    has "(cast(upvotes as int) - cast(downvotes as int))",
      :as => :score, :type => :integer, :sortable => true

    set_property :field_weights => {
      :upvotes => 15,
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

    check_tags
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

  def self.recalculate_all_hotnesses!
    Story.all.each do |s|
      s.recalculate_hotness!
    end
  end

  def as_json(options = {})
    h = super(:only => [
      :short_id,
      :created_at,
      :title,
      :url,
    ])
    h[:score] = score
    h[:comment_count] = comment_count
    h[:description] = markeddown_description
    h[:comments_url] = comments_url
    h[:submitter_user] = user

    if options && options[:with_comments]
      h[:comments] = options[:with_comments]
    end

    h
  end

  def assign_short_id
    self.short_id = ShortId.new(self.class).generate
  end

  def log_moderation
    if self.new_record? || !self.editor_user_id ||
    self.editor_user_id == self.user_id
      return
    end

    all_changes = self.changes.merge(self.tagging_changes)

    m = Moderation.new
    m.moderator_user_id = self.editor_user_id
    m.story_id = self.id

    if all_changes["is_expired"] && self.is_expired?
      m.action = "deleted story"
    elsif all_changes["is_expired"] && !self.is_expired?
      m.action = "undeleted story"
    else
      m.action = all_changes.map{|k,v| "changed #{k} from #{v[0].inspect} " <<
        "to #{v[1].inspect}" }.join(", ")
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

  # this has to happen just before save rather than in tags_a= because we need
  # to have a valid user_id
  def check_tags
    self.taggings.each do |t|
      if !t.tag.valid_for?(self.user)
        raise "#{self.user.username} does not have permission to use " <<
          "privileged tag #{t.tag.tag}"
      end
    end

    if !self.taggings.reject{|t| t.marked_for_destruction? || t.tag.is_media?
    }.any?
      errors.add(:base, "Must have at least one non-media (PDF, video) " <<
        "tag.  If no tags apply to your content, it probably doesn't " <<
        "belong here.")
    end
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
        { "User-agent" => "#{Rails.application.domain} for #{for_remote_ip}" },
        3)
    rescue
    end

    @fetched_content
  end

  def fetch_story_cache!
    if self.url.present?
      self.story_cache = StoryCacher.get_story_text(self.url)
    end
  end

  def calculated_hotness
    order = Math.log([ score.abs, 1 ].max, 10)
    if score > 0
      sign = 1
    elsif score < 0
      sign = -1
    else
      sign = 0
    end

    # TODO: as the site grows, shrink this down to 12 or so.
    window = 60 * 60 * 48

    return -(order + (sign * (self.created_at.to_f / window))).round(7)
  end

  def score
    upvotes - downvotes
  end

  def vote_summary
    r_counts = {}
    Vote.where(:story_id => self.id, :comment_id => nil).each do |v|
      r_counts[v.reason.to_s] ||= 0
      r_counts[v.reason.to_s] += v.vote
    end

    r_counts.keys.sort.map{|k|
      k == "" ? "+#{r_counts[k]}" : "#{r_counts[k]} #{Vote::STORY_REASONS[k]}"
    }.join(", ")
  end

  def generated_markeddown_description
    Markdowner.to_html(self.description, { :allow_images => true })
  end

  def description=(desc)
    self[:description] = desc.to_s.rstrip
    self.markeddown_description = self.generated_markeddown_description
  end

  def mailing_list_message_id
    "story.#{short_id}.#{created_at.to_i}@#{Rails.application.domain}"
  end

  @_tags_a = []
  def tags_a
    @_tags_a ||= self.taggings.map{|t| t.tag.tag }
  end

  def tags_a=(new_tag_names_a)
    self.taggings.each do |tagging|
      if !new_tag_names_a.include?(tagging.tag.tag)
        tagging.mark_for_destruction
      end
    end

    new_tag_names_a.each do |tag_name|
      if tag_name.to_s != "" && !self.tags.map{|t| t.tag }.include?(tag_name)
        if t = Tag.find_by_tag(tag_name)
          # we can't lookup whether the user is allowed to use this tag yet
          # because we aren't assured to have a user_id by now; we'll do it in
          # the validation with check_tags
          tg = self.taggings.build
          tg.tag_id = t.id
        end
      end
    end
  end

  def tagging_changes
    old_tags_a = self.taggings.reject{|tg| tg.new_record? }.map{|tg|
      tg.tag.tag }.join(" ")
    new_tags_a = self.taggings.reject{|tg| tg.marked_for_destruction?
      }.map{|tg| tg.tag.tag }.join(" ")

    if old_tags_a == new_tags_a
      {}
    else
      { "tags" => [ old_tags_a, new_tags_a ] }
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
    u.gsub(/^_+/, "").gsub(/_+$/, "")
  end

  def url=(u)
    # strip out stupid google analytics parameters
    if u && (m = u.match(/\A([^\?]+)\?(.+)\z/))
      params = m[2].split("&")
      params.reject!{|p|
        p.match(/^utm_(source|medium|campaign|term|content)=/) }

      u = m[1] << (params.any?? "?" << params.join("&") : "")
    end

    self[:url] = u.to_s.strip
  end

  def url_or_comments_url
    self.url.blank? ? self.comments_url : self.url
  end

  def url_is_editable_by_user?(user)
    if self.new_record?
      true
    elsif user && user.is_moderator? && self.url.present?
      true
    else
      false
    end
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

  def recalculate_hotness!
    Story.connection.execute("UPDATE #{Story.table_name} SET " <<
      "hotness = '#{self.calculated_hotness}' WHERE id = #{self.id.to_i}")
  end

  def update_comment_count!
    # calculate count after removing deleted comments and threads
    alive_count = Comment.ordered_for_story_or_thread_for_user(self.id, nil,
      nil).select{|c| !c.is_gone? }.count

    Keystore.put("story:#{self.id}:comment_count", alive_count)
  end
end
