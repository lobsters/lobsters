class Story < ApplicationRecord
  belongs_to :user
  belongs_to :merged_into_story,
             :class_name => "Story",
             :foreign_key => "merged_story_id",
             :inverse_of => :merged_stories,
             :required => false
  has_many :merged_stories,
           :class_name => "Story",
           :foreign_key => "merged_story_id",
           :inverse_of => :merged_into_story,
           :dependent => :nullify
  has_many :taggings,
           :autosave => true,
           :dependent => :destroy
  has_many :suggested_taggings, :dependent => :destroy
  has_many :suggested_titles, :dependent => :destroy
  has_many :suggested_tagging_times,
           -> { group(:tag_id).select("count(*) as times, tag_id").order('times desc') },
           :class_name => 'SuggestedTagging',
           :inverse_of => :story
  has_many :suggested_title_times,
           -> { group(:title).select("count(*) as times, title").order('times desc') },
           :class_name => 'SuggestedTitle',
           :inverse_of => :story
  has_many :comments,
           :inverse_of => :story,
           :dependent => :destroy
  has_many :tags, -> { order('tags.is_media desc, tags.tag') }, :through => :taggings
  has_many :votes, -> { where(:comment_id => nil) }, :inverse_of => :story
  has_many :voters, -> { where('votes.comment_id' => nil) },
           :through => :votes,
           :source => :user
  has_many :hidings, :class_name => 'HiddenStory', :inverse_of => :story, :dependent => :destroy
  has_many :savings, :class_name => 'SavedStory', :inverse_of => :story, :dependent => :destroy

  scope :base, -> { includes(:tags).unmerged.not_deleted }
  scope :deleted, -> { where(is_expired: true) }
  scope :not_deleted, -> { where(is_expired: false) }
  scope :unmerged, -> { where(:merged_story_id => nil) }
  scope :positive_ranked, -> { where("#{Story.score_sql} >= 0") }
  scope :low_scoring, ->(max = 5) { where("#{Story.score_sql} < ?", max) }
  scope :hottest, ->(user = nil, exclude_tags = nil) {
    base.not_hidden_by(user)
        .filter_tags(exclude_tags || [])
        .positive_ranked
        .order('hotness')
  }
  scope :recent, ->(user = nil, exclude_tags = nil) {
    base.low_scoring
        .not_hidden_by(user)
        .filter_tags(exclude_tags || [])
        .where("created_at >= ?", 10.days.ago)
        .order("stories.created_at DESC")
  }
  scope :filter_tags, ->(tags) {
    tags.empty? ? all : where.not(
      Tagging.select('TRUE')
             .where('taggings.story_id = stories.id')
             .where(tag_id: tags)
             .arel
             .exists
    )
  }
  scope :filter_tags_for, ->(user) {
    user.nil? ? all : where.not(
      Tagging.joins(tag: :tag_filters)
             .select('TRUE')
             .where('taggings.story_id = stories.id')
             .where(tag_filters: { user_id: user })
             .arel
             .exists
    )
  }
  scope :hidden_by, ->(user) {
    user.nil? ? none : joins(:hidings).merge(HiddenStory.by(user))
  }
  scope :not_hidden_by, ->(user) {
    user.nil? ? all : where.not(
      HiddenStory.select('TRUE')
        .where(Arel.sql('hidden_stories.story_id = stories.id'))
        .by(user)
        .arel
        .exists
    )
  }
  scope :saved_by, ->(user) {
    user.nil? ? none : joins(:savings).merge(SavedStory.by(user))
  }
  scope :to_tweet, -> {
    hottest(nil, Tag.where(tag: 'meta').pluck(:id))
        .where(twitter_id: nil)
        .where("#{Story.score_sql} >= 2")
        .where("created_at >= ?", 2.days.ago)
        .limit(10)
  }

  validates :title, length: { :in => 3..150 }
  validates :description, length: { :maximum => (64 * 1024) }
  validates :url, length: { :maximum => 250, :allow_nil => true }

  validates_each :merged_story_id do |record, _attr, value|
    if value.to_i == record.id
      record.errors.add(:merge_story_short_id, "id cannot be itself.")
    end
  end

  DOWNVOTABLE_DAYS = 14

  # the lowest a score can go
  DOWNVOTABLE_MIN_SCORE = -5

  # after this many minutes old, a story cannot be edited
  MAX_EDIT_MINS = (60 * 6)

  # days a story is considered recent, for resubmitting
  RECENT_DAYS = 30

  # users needed to make similar suggestions go live
  SUGGESTION_QUORUM = 2

  # let a hot story linger for this many seconds
  HOTNESS_WINDOW = 60 * 60 * 22

  # drop these words from titles when making URLs
  TITLE_DROP_WORDS = ["", "a", "an", "and", "but", "in", "of", "or", "that", "the", "to"].freeze

  # link shortening and other ad tracking domains
  TRACKING_DOMAINS = %w{ 1url.com 7.ly adf.ly al.ly bc.vc bit.do bit.ly
    bitly.com buzurl.com cur.lv cutt.us db.tt db.tt doiop.com filoops.info
    goo.gl is.gd ity.im j.mp lnkd.in ow.ly ph.dog po.st prettylinkpro.com q.gs
    qr.ae qr.net scrnch.me s.id sptfy.com t.co tinyarrows.com tiny.cc
    tinyurl.com tny.im tr.im tweez.md twitthis.com u.bb u.to v.gd vzturl.com
    wp.me ➡.ws ✩.ws x.co yep.it yourls.org zip.net }.freeze

  # URI.parse is not very lenient, so we can't use it
  URL_RE = /\A(?<protocol>https?):\/\/(?<domain>([^\.\/]+\.)+[a-z]+)(?<port>:\d+)?(\/|\z)/i.freeze

  # Dingbats, emoji, and other graphics https://www.unicode.org/charts/
  GRAPHICS_RE = /[\u{0000}-\u{001F}\u{2190}-\u{27BF}\u{1F000}-\u{1F9FF}]/.freeze

  attr_accessor :editing_from_suggestions, :editor, :fetching_ip, :is_hidden_by_cur_user,
                :is_saved_by_cur_user, :moderation_reason, :previewing, :seen_previous, :vote
  attr_writer :fetched_content

  before_validation :assign_short_id_and_upvote, :on => :create
  before_create :assign_initial_hotness
  before_save :log_moderation
  before_save :fix_bogus_chars
  after_create :mark_submitter, :record_initial_upvote
  after_save :update_merged_into_story_comments, :recalculate_hotness!

  validate do
    if self.url.present?
      already_posted_recently?
      check_not_tracking_domain
      errors.add(:url, "is not valid") unless url.match(URL_RE)
    elsif self.description.to_s.strip == ""
      errors.add(:description, "must contain text if no URL posted")
    end

    if self.title.starts_with?("Ask") && self.tags_a.include?('ask')
      errors.add(:title, " starting 'Ask #{Rails.application.name}' or similar is redundant " <<
                          "with the ask tag.")
    end
    if self.title.match(GRAPHICS_RE)
      errors.add(:title, " may not contain graphic codepoints")
    end

    if !errors.any? && self.url.blank?
      self.user_is_author = true
    end

    check_tags
  end

  def already_posted_recently?
    return false unless self.url.present? && self.new_record?

    if most_recent_similar && most_recent_similar.is_recent?
      errors.add(:url, "has already been submitted within the past #{RECENT_DAYS} days")
      true
    else
      false
    end
  end

  def check_not_tracking_domain
    return unless self.url.present? && self.new_record?

    if TRACKING_DOMAINS.include?(domain)
      errors.add(:url, "is a link shortening or ad tracking domain")
    end
  end

  # all stories with similar urls
  def self.find_similar_by_url(url)
    urls = [url.to_s]
    urls2 = [url.to_s]

    # https
    urls.each do |u|
      urls2.push u.gsub(/^http:\/\//i, "https://")
      urls2.push u.gsub(/^https:\/\//i, "http://")
    end
    urls = urls2.uniq

    # trailing slash or index.html
    urls.each do |u|
      u_without_slash = u.gsub(/\/+\z/, "")
      urls2.push u_without_slash
      urls2.push u_without_slash + "/"
      urls2.push u_without_slash + "/index.htm"
      urls2.push u_without_slash + "/index.html"
      urls2.push u.gsub(/\/index.html?\z/, "")
    end
    urls = urls2.uniq

    # www prefix
    urls.each do |u|
      urls2.push u.gsub(/^(https?:\/\/)www\d*\./i) {|_| $1 }
      urls2.push u.gsub(/^(https?:\/\/)/i) {|_| "#{$1}www." }
    end
    urls = urls2.uniq

    # if a previous submission was moderated, return it to block it from being
    # submitted again
    Story
      .where(:url => urls)
      .where("is_expired = ? OR is_moderated = ?", false, true)
  end

  # doesn't include deleted/moderated/merged stories
  def similar_stories
    return [] unless self.url.present?

    @_similar_stories ||= Story.find_similar_by_url(self.url).order("id DESC")
    # do not include this story itself or any story merged into it
    if self.id?
      @_similar_stories = @_similar_stories.where.not(id: self.id)
        .where('merged_story_id is null or merged_story_id != ?', self.id)
    end
    # do not include the story this one is merged into
    if self.merged_story_id?
      @_similar_stories = @_similar_stories.where('id != ?', self.merged_story_id)
    end
    @_similar_stories
  end

  def public_similar_stories
    @_public_similar_stories ||= similar_stories.empty? ? [] : similar_stories.base
  end

  def most_recent_similar
    similar_stories.first
  end

  def self.recalculate_all_hotnesses!
    # do the front page first, since find_each can't take an order
    Story.order("id DESC").limit(100).each(&:recalculate_hotness!)
    Story.find_each(&:recalculate_hotness!)
    true
  end

  def self.score_sql
    Arel.sql("(CAST(upvotes AS #{votes_cast_type}) - " <<
      "CAST(downvotes AS #{votes_cast_type}))")
  end

  def self.votes_cast_type
    Story.connection.adapter_name.match(/mysql/i) ? "signed" : "integer"
  end

  def archive_url
    "https://archive.is/#{CGI.escape(self.url)}"
  end

  def as_json(options = {})
    h = [
      :short_id,
      :short_id_url,
      :created_at,
      :title,
      :url,
      :score,
      :upvotes,
      :downvotes,
      { :comment_count => :comments_count },
      { :description => :markeddown_description },
      :comments_url,
      { :submitter_user => :user },
      { :tags => self.tags.map(&:tag).sort },
    ]

    if options && options[:with_comments]
      h.push(:comments => options[:with_comments])
    end

    js = {}
    h.each do |k|
      if k.is_a?(Symbol)
        js[k] = self.send(k)
      elsif k.is_a?(Hash)
        if k.values.first.is_a?(Symbol)
          js[k.keys.first] = self.send(k.values.first)
        else
          js[k.keys.first] = k.values.first
        end
      end
    end

    js
  end

  def assign_initial_hotness
    self.hotness = self.calculated_hotness
  end

  def assign_short_id_and_upvote
    self.short_id = ShortId.new(self.class).generate
    self.upvotes = 1
  end

  def calculated_hotness
    # take each tag's hotness modifier into effect, and give a slight bump to
    # stories submitted by the author
    base = self.tags.sum(:hotness_mod) + (self.user_is_author? && self.url.present? ? 0.25 : 0.0)

    # give a story's comment votes some weight, ignoring submitter's comments
    cpoints = self.merged_comments
      .where("user_id <> ?", self.user_id)
      .select(:upvotes, :downvotes)
      .map {|c|
        if base < 0
          # in stories already starting out with a bad hotness mod, only look
          # at the downvotes to find out if this tire fire needs to be put out
          c.downvotes * -0.5
        else
          c.upvotes + 1 - c.downvotes
        end
      }
      .inject(&:+).to_f * 0.5

    # mix in any stories this one cannibalized
    cpoints += self.merged_stories.map(&:score).inject(&:+).to_f

    # if a story has many comments but few votes, it's probably a bad story, so
    # cap the comment points at the number of upvotes
    if cpoints > self.upvotes
      cpoints = self.upvotes
    end

    # don't immediately kill stories at 0 by bumping up score by one
    order = Math.log([(score + 1).abs + cpoints, 1].max, 10)
    if score > 0
      sign = 1
    elsif score < 0
      sign = -1
    else
      sign = 0
    end

    return -((order * sign) + base +
      ((self.created_at || Time.current).to_f / HOTNESS_WINDOW)).round(7)
  end

  def can_be_seen_by_user?(user)
    if is_gone? && !(user && (user.is_moderator? || user.id == self.user_id))
      return false
    end

    true
  end

  def can_have_images?
    # doesn't test self.editor so a user can't trick a mod into editing a
    # story to enable an image
    self.user.try(:is_moderator?)
  end

  def can_have_suggestions_from_user?(user)
    if !user || (user.id == self.user_id) || !user.can_offer_suggestions?
      return false
    end

    if self.taggings.select {|t| t.tag && t.tag.privileged? }.any?
      return false
    end

    return true
  end

  # this has to happen just before save rather than in tags_a= because we need
  # to have a valid user_id
  def check_tags
    u = self.editor || self.user

    self.taggings.each do |t|
      if !t.tag.valid_for?(u)
        raise "#{u.username} does not have permission to use privileged tag #{t.tag.tag}"
      elsif t.tag.inactive? && t.new_record? && !t.marked_for_destruction?
        # stories can have inactive tags as long as they existed before
        raise "#{u.username} cannot add inactive tag #{t.tag.tag}"
      end
    end

    if self.taggings.reject {|t| t.marked_for_destruction? || t.tag.is_media? }.empty?
      errors.add(:base, "Must have at least one non-media (PDF, video) " <<
        "tag.  If no tags apply to your content, it probably doesn't " <<
        "belong here.")
    end
  end

  def comments_path
    "#{short_id_path}/#{self.title_as_url}"
  end

  def comments_url
    "#{short_id_url}/#{self.title_as_url}"
  end

  def description=(desc)
    self[:description] = desc.to_s.rstrip
    self.markeddown_description = self.generated_markeddown_description
  end

  def description_or_story_cache(chars = 0)
    s = if self.description.present?
      self.markeddown_description.gsub(/<[^>]*>/, "")
    else
      self.story_cache
    end

    if chars > 0 && s.to_s.length > chars
      # remove last truncated word
      s = s.to_s[0, chars].gsub(/ [^ ]*\z/, "")
    end

    HTMLEntities.new.decode(s.to_s)
  end

  def domain_search_url
    "/search?order=newest&q=domain:#{self.domain}"
  end

  def fetch_story_cache!
    if self.url.present?
      self.story_cache = StoryCacher.get_story_text(self)
    end
  end

  def fix_bogus_chars
    # this is needlessly complicated to work around character encoding issues
    # that arise when doing just self.title.to_s.gsub(160.chr, "")
    self.title = self.title.to_s.split("").map {|chr|
      if chr.ord == 160
        " "
      else
        chr
      end
    }.join("")

    true
  end

  def generated_markeddown_description
    Markdowner.to_html(self.description, allow_images: self.can_have_images?)
  end

  def give_upvote_or_downvote_and_recalculate_hotness!(upvote, downvote)
    self.upvotes += upvote.to_i
    self.downvotes += downvote.to_i

    Story.connection.execute("UPDATE #{Story.table_name} SET " <<
      "upvotes = COALESCE(upvotes, 0) + #{upvote.to_i}, " <<
      "downvotes = COALESCE(downvotes, 0) + #{downvote.to_i}, " <<
      "hotness = '#{self.calculated_hotness}' WHERE id = #{self.id.to_i}")
  end

  def has_suggestions?
    self.suggested_taggings.any? || self.suggested_titles.any?
  end

  def hider_count
    @hider_count ||= HiddenStory.where(:story_id => self.id).count
  end

  def html_class_for_user
    c = []
    if !self.user.is_active?
      c.push "inactive_user"
    elsif self.user.is_new?
      c.push "new_user"
    elsif self.user_is_author?
      c.push "user_is_author"
    end

    c.join("")
  end

  def is_downvotable?
    if self.created_at && self.score >= DOWNVOTABLE_MIN_SCORE
      Time.current - self.created_at <= DOWNVOTABLE_DAYS.days
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
        return (Time.current.to_i - self.created_at.to_i < (60 * MAX_EDIT_MINS))
      end
    else
      return false
    end
  end

  def is_gone?
    is_expired? || (self.user.is_banned? && score < 0)
  end

  def is_hidden_by_user?(user)
    !!HiddenStory.find_by(:user_id => user.id, :story_id => self.id)
  end

  def is_recent?
    self.created_at >= RECENT_DAYS.days.ago
  end

  def is_saved_by_user?(user)
    !!SavedStory.find_by(:user_id => user.id, :story_id => self.id)
  end

  def is_unavailable
    self.unavailable_at != nil
  end

  def is_unavailable=(what)
    self.unavailable_at = (what.to_i == 1 && !self.is_unavailable ? Time.current : nil)
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
    if self.new_record? ||
       (!self.editing_from_suggestions && (!self.editor || self.editor.id == self.user_id))
      return
    end

    all_changes = self.changes.merge(self.tagging_changes)
    all_changes.delete("unavailable_at")

    if !all_changes.any?
      return
    end

    m = Moderation.new
    if self.editing_from_suggestions
      m.is_from_suggestions = true
    else
      m.moderator_user_id = self.editor.try(:id)
    end
    m.story_id = self.id

    if all_changes["is_expired"] && self.is_expired?
      m.action = "deleted story"
    elsif all_changes["is_expired"] && !self.is_expired?
      m.action = "undeleted story"
    else
      m.action = all_changes.map {|k, v|
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

  def merged_comments
    # TODO: make this a normal has_many?
    Comment.where(:story_id => Story.select(:id)
      .where(:merged_story_id => self.id) + [self.id])
  end

  def merge_story_short_id=(sid)
    self.merged_story_id = sid.present? ? Story.where(:short_id => sid).pluck(:id).first : nil
  end

  def merge_story_short_id
    self.merged_story_id ? self.merged_into_story.try(:short_id) : nil
  end

  def recalculate_hotness!
    update_column :hotness, calculated_hotness
  end

  def record_initial_upvote
    Vote.vote_thusly_on_story_or_comment_for_user_because(1, self.id, nil, self.user_id, nil, false)
  end

  def score
    upvotes - downvotes
  end

  def short_id_path
    Rails.application.routes.url_helpers.root_path + "s/#{self.short_id}"
  end

  def short_id_url
    Rails.application.root_url + "s/#{self.short_id}"
  end

  def tagging_changes
    old_tags_a = self.taggings.reject(&:new_record?).map {|tg| tg.tag.tag }.join(" ")
    new_tags_a = self.taggings.reject(&:marked_for_destruction?).map {|tg| tg.tag.tag }.join(" ")

    if old_tags_a == new_tags_a
      {}
    else
      { "tags" => [old_tags_a, new_tags_a] }
    end
  end

  def tags_a
    @_tags_a ||= self.taggings.reject(&:marked_for_destruction?).map {|t| t.tag.tag }
  end

  def tags_a=(new_tag_names_a)
    self.taggings.each do |tagging|
      if !new_tag_names_a.include?(tagging.tag.tag)
        tagging.mark_for_destruction
      end
    end

    new_tag_names_a.uniq.each do |tag_name|
      if tag_name.to_s != "" && !self.tags.exists?(:tag => tag_name)
        if (t = Tag.active.find_by(:tag => tag_name))
          # we can't lookup whether the user is allowed to use this tag yet
          # because we aren't assured to have a user_id by now; we'll do it in
          # the validation with check_tags
          self.taggings.build(tag_id: t.id)
        end
      end
    end
  end

  def save_suggested_tags_a_for_user!(new_tag_names_a, user)
    st = self.suggested_taggings.where(:user_id => user.id)

    st.each do |tagging|
      if !new_tag_names_a.include?(tagging.tag.tag)
        tagging.destroy
      end
    end

    st.reload

    new_tag_names_a.each do |tag_name|
      # XXX: AR bug? st.exists?(:tag => tag_name) does not work
      if tag_name.to_s != "" && !st.map {|x| x.tag.tag }.include?(tag_name)
        if (t = Tag.active.find_by(:tag => tag_name)) &&
           t.valid_for?(user)
          tg = self.suggested_taggings.build
          tg.user_id = user.id
          tg.tag_id = t.id
          tg.save!

          st.reload
        else
          next
        end
      end
    end

    # if enough users voted on the same set of replacement tags, do it
    tag_votes = {}
    self.suggested_taggings.group_by(&:user_id).each do |_u, stg|
      stg.each do |s|
        tag_votes[s.tag.tag] ||= 0
        tag_votes[s.tag.tag] += 1
      end
    end

    final_tags = []
    tag_votes.each do |k, v|
      if v >= SUGGESTION_QUORUM
        final_tags.push k
      end
    end

    if final_tags.any? && (final_tags.sort != self.tags_a.sort)
      Rails.logger.info "[s#{self.id}] promoting suggested tags " <<
                        "#{final_tags.inspect} instead of #{self.tags_a.inspect}"
      self.editor = nil
      self.editing_from_suggestions = true
      self.moderation_reason = "Automatically changed from user suggestions"
      self.tags_a = final_tags.sort
      if !self.save
        Rails.logger.error "[s#{self.id}] failed auto promoting: " <<
                           self.errors.inspect
      end
    end
  end

  def save_suggested_title_for_user!(title, user)
    st = self.suggested_titles.find_by(:user_id => user.id)
    if !st
      st = self.suggested_titles.build
      st.user_id = user.id
    end
    st.title = title
    st.save!

    # if enough users voted on the same exact title, save it
    title_votes = {}
    self.suggested_titles.each do |s|
      title_votes[s.title] ||= 0
      title_votes[s.title] += 1
    end

    title_votes.sort_by {|_k, v| v }.reverse_each do |kv|
      if kv[1] >= SUGGESTION_QUORUM
        Rails.logger.info "[s#{self.id}] promoting suggested title " <<
                          "#{kv[0].inspect} instead of #{self.title.inspect}"
        self.editor = nil
        self.editing_from_suggestions = true
        self.moderation_reason = "Automatically changed from user suggestions"
        self.title = kv[0]
        if !self.save
          Rails.logger.error "[s#{self.id}] failed auto promoting: " <<
                             self.errors.inspect
        end

        break
      end
    end
  end

  def title=(t)
    # change unicode whitespace characters into real spaces
    self[:title] = t.strip.gsub(/[\.,;:!]*$/, '')
  end

  def title_as_url
    max_len = 35
    wl = 0
    words = []

    self.title
         .parameterize
         .gsub(/[^a-z0-9]/, "_")
         .split("_")
         .reject {|z| TITLE_DROP_WORDS.include?(z) }
         .each do |w|
      if wl + w.length <= max_len
        words.push w
        wl += w.length
      else
        if wl == 0
          words.push w[0, max_len]
        end
        break
      end
    end

    if words.empty?
      words.push "_"
    end

    words.join("_").gsub(/_-_/, "-")
  end

  def to_param
    self.short_id
  end

  def update_availability
    if self.is_unavailable && !self.unavailable_at
      self.unavailable_at = Time.current
    elsif self.unavailable_at && !self.is_unavailable
      self.unavailable_at = nil
    end
  end

  def update_comments_count!
    comments = self.merged_comments.arrange_for_user(nil)

    # calculate count after removing deleted comments and threads
    self.update_column :comments_count, (self.comments_count = comments.count {|c| !c.is_gone? })

    self.recalculate_hotness!
  end

  def update_merged_into_story_comments
    if self.merged_into_story
      self.merged_into_story.update_comments_count!
    end
  end

  def domain
    return @domain if @domain
    set_domain self.url.match(URL_RE) if self.url
  end

  def set_domain match
    @domain = match ? match[:domain].sub(/^www\d*\./, '') : nil
  end

  def url=(u)
    super(u.try(:strip)) or return if u.blank?

    if (match = u.match(URL_RE))
      # remove well-known port for http and https if present
      @url_port = match[:port]
      if match[:protocol] == 'http'  && match[:port] == ':80' ||
         match[:protocol] == 'https' && match[:port] == ':443'
        u = u[0...match.begin(3)] + u[match.end(3)..-1]
        @url_port = nil
      end
    end
    set_domain match

    # strip out tracking query params
    if (match = u.match(/\A([^\?]+)\?(.+)\z/))
      params = match[2].split(/[&\?]/)
      # utm_ is google and many others; sk is medium
      params.reject! {|p| p.match(/^utm_(source|medium|campaign|term|content)=|^sk=|^fbclid=/) }
      u = match[1] << (params.any?? "?" << params.join("&") : "")
    end

    super(u)
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

  def url_or_comments_path
    self.url.presence || self.comments_path
  end

  def url_or_comments_url
    self.url.presence || self.comments_url
  end

  def vote_summary_for(user)
    r_counts = {}
    r_whos = {}
    votes.includes(user && user.is_moderator? ? :user : nil).find_each do |v|
      next if v.vote == 0
      r_counts[v.reason.to_s] ||= 0
      r_counts[v.reason.to_s] += v.vote
      if user && user.is_moderator?
        r_whos[v.reason.to_s] ||= []
        r_whos[v.reason.to_s].push v.user.username
      end
    end

    r_counts.keys.sort.map {|k|
      if k == ""
        "+#{r_counts[k]}"
      else
        "#{r_counts[k]} " +
          (Vote::STORY_REASONS[k] || Vote::OLD_STORY_REASONS[k] || k) +
          (user && user.is_moderator? ? " (#{r_whos[k].join(', ')})" : "")
      end
    }.join(", ")
  end

  def fetched_attributes
    return @fetched_attributes if @fetched_attributes

    @fetched_attributes = {
      :url => self.url,
      :title => "",
    }

    # security: do not connect to arbitrary user-submitted ports
    return @fetched_attributes if @url_port

    if !@fetched_content
      begin
        s = Sponge.new
        s.timeout = 3
        @fetched_content = s.fetch(self.url, :get, nil, nil, {
          "User-agent" => "#{Rails.application.domain} for #{self.fetching_ip}",
        }, 3).body.encode!(invalid: :replace, undef: :replace, replace: '')
      rescue
        return @fetched_attributes
      end
    end

    parsed = Nokogiri::HTML(@fetched_content.to_s)

    # parse best title from html tags
    # try <meta property="og:title"> first, it probably won't have the site
    # name
    title = ""
    begin
      title = parsed.at_css("meta[property='og:title']")
        .attributes["content"].text
    rescue
    end

    # then try <meta name="title">
    if title.to_s == ""
      begin
        title = parsed.at_css("meta[name='title']").attributes["content"].text
      rescue
      end
    end

    # then try plain old <title>
    if title.to_s == ""
      title = parsed.at_css("title").try(:text).to_s
    end

    # see if the site name is available, so we can strip it out in case it was
    # present in the fetched title
    begin
      site_name = parsed.at_css("meta[property='og:site_name']")
        .attributes["content"].text

      if site_name.present? &&
         site_name.length < title.length &&
         title[-(site_name.length), site_name.length] == site_name
        title = title[0, title.length - site_name.length]

        # remove title/site name separator
        if title.match(/ [ \-\|\u2013] $/)
          title = title[0, title.length - 3]
        end
      end
    rescue
    end

    @fetched_attributes[:title] = title

    # now get canonical version of url (though some cms software puts incorrect
    # urls here, hopefully the user will notice)
    begin
      if (cu = parsed.at_css("link[rel='canonical']").attributes["href"] .text).present? &&
         (ucu = URI.parse(cu)) && ucu.scheme.present? &&
         ucu.host.present?
        @fetched_attributes[:url] = cu
      end
    rescue
    end

    @fetched_attributes
  end
end
