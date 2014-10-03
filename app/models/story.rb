class Story < ActiveRecord::Base
  belongs_to :user
  belongs_to :merged_into_story,
    :class_name => "Story",
    :foreign_key => "merged_story_id"
  has_many :merged_stories,
    :class_name => "Story",
    :foreign_key => "merged_story_id"
  has_many :taggings,
    :autosave => true
  has_many :comments,
    :inverse_of => :story
  has_many :tags, :through => :taggings
  has_many :votes, -> { where(:comment_id => nil) }
  has_many :voters, -> { where('votes.comment_id' => nil) },
    :through => :votes,
    :source => :user

  scope :unmerged, -> { where(:merged_story_id => nil) }

  validates_length_of :title, :in => 3..150
  validates_length_of :description, :maximum => (64 * 1024)
  validates_presence_of :user_id

  DOWNVOTABLE_DAYS = 14

  # after this many minutes old, a story cannot be edited
  MAX_EDIT_MINS = 90

  # days a story is considered recent, for resubmitting
  RECENT_DAYS = 30

  attr_accessor :vote, :already_posted_story, :fetched_content, :previewing,
    :seen_previous
  attr_accessor :editor, :moderation_reason, :merge_story_short_id

  before_validation :assign_short_id_and_upvote,
    :on => :create
  before_save :log_moderation
  after_create :mark_submitter, :record_initial_upvote
  after_save :update_merged_into_story_comments

  validate do
    if self.url.present?
      # URI.parse is not very lenient, so we can't use it

      if self.url.match(/\Ahttps?:\/\/([^\.]+\.)+[a-z]+(\/|\z)/)
        if self.new_record? && (s = Story.find_similar_by_url(self.url))
          self.already_posted_story = s
          if s.is_recent?
            errors.add(:url, "has already been submitted within the past " <<
              "#{RECENT_DAYS} days")
          end
        end
      else
        errors.add(:url, "is not valid")
      end
    elsif self.description.to_s.strip == ""
      errors.add(:description, "must contain text if no URL posted")
    end

    check_tags
  end

  def self.find_similar_by_url(url)
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

    if s = Story.where(:url => urls, :is_expired => false).order("id DESC").first
      return s
    end

    false
  end

  def self.recalculate_all_hotnesses!
    Story.all.order("id DESC").each do |s|
      s.recalculate_hotness!
    end
    true
  end

  def self.votes_cast_type
    Story.connection.adapter_name.match(/mysql/i) ? "signed" : "integer"
  end

  def as_json(options = {})
    h = super(:only => [
      :short_id,
      :created_at,
      :title,
      :url,
    ])
    h[:score] = score
    h[:comment_count] = comments_count
    h[:description] = markeddown_description
    h[:comments_url] = comments_url
    h[:submitter_user] = user
    h[:tags] = self.tags.map{|t| t.tag }.sort

    if options && options[:with_comments]
      h[:comments] = options[:with_comments]
    end

    h
  end

  def assign_short_id_and_upvote
    self.short_id = ShortId.new(self.class).generate
    self.upvotes = 1
  end

  def calculated_hotness
    base = 10
    self.tags.select{|t| t.hotness_mod != 0 }.each do |t|
      base -= t.hotness_mod
    end

    # prevent the submitter's own comments from affecting the score
    ccount = self.comments.where("user_id != ?", self.user_id).count

    # don't immediately kill stories at 0 by bumping up score by one
    order = Math.log([ (score + 1).abs + ccount, 1 ].max, base)
    if score > 0
      sign = 1
    elsif score < 0
      sign = -1
    else
      sign = 0
    end

    # TODO: as the site grows, shrink this down to 12 or so.
    window = 60 * 60 * 24

    return -((order * sign) + (self.created_at.to_f / window)).round(7)
  end

  def can_be_seen_by_user?(user)
    if is_gone? && !(user && (user.is_moderator? || user.id == self.user_id))
      return false
    end

    true
  end

  # this has to happen just before save rather than in tags_a= because we need
  # to have a valid user_id
  def check_tags
    u = self.editor || self.user

    self.taggings.each do |t|
      if !t.tag.valid_for?(u)
        raise "#{u.username} does not have permission to use privileged " <<
          "tag #{t.tag.tag}"
      elsif t.tag.inactive? && !t.new_record?
        # stories can have inactive tags as long as they existed before
        raise "#{u.username} cannot add inactive tag #{t.tag.tag}"
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

  def description=(desc)
    self[:description] = desc.to_s.rstrip
    self.markeddown_description = self.generated_markeddown_description
  end

  def domain
    if self.url.blank?
      nil
    else
      # URI.parse is not very lenient, so we can't use it
      self.url.
        gsub(/^[^:]+:\/\//, ""). # proto
        gsub(/\/.*/, "").        # path
        gsub(/:\d+$/, "").       # possible port
        gsub(/^www\d*\./, "")    # possible "www3." in host
    end
  end

  def fetch_story_cache!
    if self.url.present?
      self.story_cache = StoryCacher.get_story_text(self.url)
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

  def fetched_title(for_remote_ip = nil)
    doc = Nokogiri::HTML(fetched_content(for_remote_ip).to_s)
    if doc
      return doc.at_css("title").try(:text)
    else
      return ""
    end
  end

  def generated_markeddown_description
    Markdowner.to_html(self.description, { :allow_images => true })
  end

  def give_upvote_or_downvote_and_recalculate_hotness!(upvote, downvote)
    self.upvotes += upvote.to_i
    self.downvotes += downvote.to_i

    Story.connection.execute("UPDATE #{Story.table_name} SET " <<
      "upvotes = COALESCE(upvotes, 0) + #{upvote.to_i}, " <<
      "downvotes = COALESCE(downvotes, 0) + #{downvote.to_i}, " <<
      "hotness = '#{self.calculated_hotness}' WHERE id = #{self.id.to_i}")
  end

  def hider_count
    @hider_count ||= Vote.where(:story_id => self.id, :comment_id => nil,
      :vote => 0).count
  end

  def is_downvotable?
    if self.created_at
      Time.now - self.created_at <= DOWNVOTABLE_DAYS.days
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

  def is_gone?
    is_expired?
  end

  def is_recent?
    self.created_at >= RECENT_DAYS.days.ago
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

  def log_moderation
    if self.new_record? || !self.editor || self.editor.id == self.user_id
      return
    end

    all_changes = self.changes.merge(self.tagging_changes)

    m = Moderation.new
    m.moderator_user_id = self.editor.try(:id)
    m.story_id = self.id

    if all_changes["is_expired"] && self.is_expired?
      m.action = "deleted story"
    elsif all_changes["is_expired"] && !self.is_expired?
      m.action = "undeleted story"
    else
      m.action = all_changes.map{|k,v|
        if k == "merged_story_id"
          if v[1]
            "merged into #{self.merged_into_story.short_id} " <<
              "(#{self.merged_into_story.title})"
          else
            "unmerged from another story"
          end
        else
          "changed #{k} from #{v[0].inspect} to #{v[1].inspect}"
        end
      }.join(", ")
    end

    m.reason = self.moderation_reason
    m.save

    self.is_moderated = true
  end

  def mailing_list_message_id
    "story.#{short_id}.#{created_at.to_i}@#{Rails.application.domain}"
  end

  def mark_submitter
    Keystore.increment_value_for("user:#{self.user_id}:stories_submitted")
  end

  def merge_into_story!(story)
    self.merged_story_id = story.id
    self.save!
  end

  def merged_comments
    # TODO: make this a normal has_many?
    Comment.where(:story_id => Story.select(:id).
      where(:merged_story_id => self.id) + [ self.id ])
  end

  def merge_story_short_id=(sid)
    self.merged_story_id = sid.present??
      Story.where(:short_id => sid).first.id : nil
  end

  def recalculate_hotness!
    update_column :hotness, calculated_hotness
  end

  def record_initial_upvote
    Vote.vote_thusly_on_story_or_comment_for_user_because(1, self.id, nil,
      self.user_id, nil, false)
  end

  def short_id_url
    Rails.application.routes.url_helpers.root_url + "s/#{self.short_id}"
  end

  def score
    upvotes - downvotes
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
      if tag_name.to_s != "" && !self.tags.exists?(:tag => tag_name)
        if t = Tag.active.where(:tag => tag_name).first
          # we can't lookup whether the user is allowed to use this tag yet
          # because we aren't assured to have a user_id by now; we'll do it in
          # the validation with check_tags
          tg = self.taggings.build
          tg.tag_id = t.id
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
    u.gsub(/^_+/, "").gsub(/_+$/, "")
  end

  def to_param
    self.short_id
  end

  def update_comments_count!
    comments = self.merged_comments.arrange_for_user(nil)

    # calculate count after removing deleted comments and threads
    self.update_column :comments_count,
      (self.comments_count = comments.count{|c| !c.is_gone? })

    self.recalculate_hotness!
  end

  def update_merged_into_story_comments
    if self.merged_into_story
      self.merged_into_story.update_comments_count!
    end
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

  def url_is_editable_by_user?(user)
    if self.new_record?
      true
    elsif user && user.is_moderator? && self.url.present?
      true
    else
      false
    end
  end

  def url_or_comments_url
    self.url.blank? ? self.comments_url : self.url
  end

  def vote_summary_for(user)
    r_counts = {}
    r_whos = {}
    Vote.where(:story_id => self.id, :comment_id => nil).where("vote != 0").each do |v|
      r_counts[v.reason.to_s] ||= 0
      r_counts[v.reason.to_s] += v.vote
      if user && user.is_moderator?
        r_whos[v.reason.to_s] ||= []
        r_whos[v.reason.to_s].push v.user.username
      end
    end

    r_counts.keys.sort.map{|k|
      if k == ""
        "+#{r_counts[k]}"
      else
        "#{r_counts[k]} " +
          (Vote::STORY_REASONS[k] || Vote::OLD_STORY_REASONS[k] || k) +
          (user && user.is_moderator?? " (#{r_whos[k].join(", ")})" : "")
      end
    }.join(", ")
  end
end
