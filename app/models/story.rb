class Story < ApplicationRecord
  belongs_to :user
  belongs_to :domain, optional: true
  belongs_to :merged_into_story,
             :class_name => "Story",
             :foreign_key => "merged_story_id",
             :inverse_of => :merged_stories,
             :optional => true
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
  has_one :story_text, foreign_key: :id, dependent: :destroy, inverse_of: :story

  scope :base, ->(user) {
    q = includes(:tags).unmerged
    user && user.is_moderator? ? q.preload(:suggested_taggings, :suggested_titles) : q.not_deleted
  }
  scope :deleted, -> { where(is_deleted: true) }
  scope :not_deleted, -> { where(is_deleted: false) }
  scope :unmerged, -> { where(:merged_story_id => nil) }
  scope :positive_ranked, -> { where("score >= 0") }
  scope :low_scoring, ->(max = 5) { where("score < ?", max) }
  scope :front_page, -> { hottest.limit(StoriesPaginator::STORIES_PER_PAGE) }
  scope :hottest, ->(user = nil, exclude_tags = nil) {
    base(user).not_hidden_by(user)
        .filter_tags(exclude_tags || [])
        .positive_ranked
        .order('hotness')
  }
  scope :recent, ->(user = nil, exclude_tags = nil) {
    base(user).not_hidden_by(user)
        .filter_tags(exclude_tags || [])
        .low_scoring
        .where("created_at >= ?", 10.days.ago)
        .where.not(id: front_page.ids)
        .order("stories.created_at DESC")
  }
  scope :filter_tags, ->(tags) {
    tags.empty? ? all : where(
      Story.arel_table[:id].not_in(
        Tagging.where(tag_id: tags).select(:story_id).arel
      )
    )
  }
  scope :filter_tags_for, ->(user) {
    user.nil? ? all : where(
      Story.arel_table[:id].not_in(
        Tagging.joins(tag: :tag_filters)
          .where(tag_filters: { user_id: user })
          .select(:story_id).arel
      )
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
        .where("score >= 2")
        .where("created_at >= ?", 2.days.ago)
        .limit(10)
  }

  validates :title, length: { :in => 3..150 }
  validates :description, length: { :maximum => (64 * 1024) }
  validates :url, length: { :maximum => 250, :allow_nil => true }
  validates :short_id, presence: true, length: { :maximum => 6 }
  validates :markeddown_description, length: { :maximum => 16_777_215, :allow_nil => true }
  validates :twitter_id, length: { :maximum => 20, :allow_nil => true }

  validates_each :merged_story_id do |record, _attr, value|
    if value.to_i == record.id
      record.errors.add(:merge_story_short_id, "id cannot be itself.")
    end
  end

  COMMENTABLE_DAYS = 90
  FLAGGABLE_DAYS = 14

  # the lowest a score can go
  FLAGGABLE_MIN_SCORE = -5

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

  # URI.parse is not very lenient, so we can't use it
  URL_RE = /\A(?<protocol>https?):\/\/(?<domain>([^\.\/]+\.)+[a-z\-]+)(?<port>:\d+)?(\/|\z)/i.freeze

  # Dingbats, emoji, and other graphics https://www.unicode.org/charts/
  GRAPHICS_RE = /[\u{0000}-\u{001F}\u{2190}\u{2192}-\u{27BF}\u{1F000}-\u{1F9FF}]/.freeze

  attr_accessor :editing_from_suggestions, :editor, :fetching_ip,
                :is_hidden_by_cur_user, :latest_comment_id,
                :is_saved_by_cur_user, :moderation_reason, :previewing,
                :seen_previous, :vote
  attr_writer :fetched_response

  before_validation :assign_short_id_and_score, :on => :create
  before_create :assign_initial_hotness
  before_save :log_moderation
  before_save :fix_bogus_chars
  after_create :mark_submitter, :record_initial_upvote
  after_save :update_merged_into_story_comments, :recalculate_hotness!

  validate do
    if self.url.present?
      already_posted_recently?
      check_not_tracking_domain
      check_not_new_domain_from_new_user
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

  def accepting_comments?
    !self.is_gone? &&
      !self.previewing &&
      (self.new_record? || self.created_at.after?(COMMENTABLE_DAYS.days.ago))
  end

  def already_posted_recently?
    return false unless self.url.present? && self.new_record?

    if most_recent_similar && most_recent_similar.is_recent?
      errors.add(:url, "has already been submitted within the past #{RECENT_DAYS} days")
      true
    elsif most_recent_similar && self.user && self.user.is_new?
      errors.add(:url, "cannot be resubmitted by new users")
      true
    else
      false
    end
  end

  def check_not_new_domain_from_new_user
    return unless self.url.present? && self.new_record? && self.domain

    if self.user && self.user.is_new? && self.domain.stories.not_deleted.count == 0
      ModNote.tattle_on_story_domain!(self, "new user with new")
      errors.add :url, <<-EXPLANATION
        is an unseen domain from a new user. We restrict this to discourage
        self-promotion and give you time to learn about topicality. Skirting
        this with a URL shortener or tweet or something will probably earn a ban.
      EXPLANATION
    end
  end

  def check_not_tracking_domain
    return unless self.url.present? && self.new_record? && self.domain

    if self.domain.banned?
      ModNote.tattle_on_story_domain!(self, "banned")
      errors.add(:url, "is from banned domain #{self.domain.domain}: #{self.domain.banned_reason}")
    end
  end

  # all stories with similar urls
  def self.find_similar_by_url(url)
    url = url.to_s.gsub('[', '\\[')
    url = url.to_s.gsub(']', '\\]')
    urls = [url.to_s.gsub(/(#.*)/, "")]
    urls2 = [url.to_s.gsub(/(#.*)/, "")]
    urls_with_trailing_pound = []

    # arxiv html page and its pdf link based off the [arxiv identifier](https://arxiv.org/help/arxiv_identifier)
    if /^https?:\/\/(www\d*\.)?arxiv.org/i.match(url)
      urls.each do |u|
        urls2.push u.gsub(/(arxiv.org\/)abs(\/\d{4}.\d{4,5})/i, '\1pdf\2')
        urls2.push u.gsub(/(arxiv.org\/)abs(\/\d{4}.\d{4,5})/i, '\1pdf\2.pdf')
        urls2.push u.gsub(/(arxiv.org\/)pdf(\/\d{4}.\d{4,5})(.pdf)?/i, '\1abs\2')
      end
      urls = urls2.uniq
    end

    # www.youtube.com
    # m.youtube.com
    # youtube.com          redirects to www.youtube.com
    # youtu.be             redirects to www.youtube.com
    # www.m.youtube.com    doesn't work
    # www.youtu.be         doesn't exist
    # m.youtu.be           doesn't exist
    if /^https?:\/\/((?:www\d*|m)\.)?(youtube\.com|youtu\.be)/i.match(url)
      urls.each do |u|
        id = /^https?:\/\/(?:(?:m|www)\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([A-z0-9\-_]+)/i
          .match(u)[1]

        urls2.push "https://www.youtube.com/watch?v=#{id}"
        # In theory, youtube redirects https://youtube.com to https://www.youtube.com
        # let's check it just in case
        urls2.push "https://youtube.com/watch?v=#{id}"
        urls2.push "https://youtu.be/#{id}"
        urls2.push "https://m.youtube.com/watch?v=#{id}"
      end
      urls = urls2.uniq
    end

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

    # trailing pound
    urls.each do |u|
      urls_with_trailing_pound.push u + "#"
    end

    # if a previous submission was moderated, return it to block it from being
    # submitted again
    Story
      .where(:url => urls)
      .or(Story.where("url RLIKE ?", urls_with_trailing_pound.join(".|")))
      .where("is_deleted = ? OR is_moderated = ?", false, true)
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

  def public_similar_stories(user)
    @_public_similar_stories ||= similar_stories.empty? ? [] : similar_stories.base(user)
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

  def archiveorg_url
    # This will redirect to the latest version they have
    "https://web.archive.org/web/3/#{CGI.escape(self.url)}"
  end

  def archivetoday_url
    "https://archive.today/#{CGI.escape(self.url)}"
  end

  def ghost_url
    "https://ghostarchive.org/search?term=#{CGI.escape(self.url)}"
  end

  def as_json(options = {})
    h = [
      :short_id,
      :short_id_url,
      :created_at,
      :title,
      :url,
      :score,
      :score,
      :flags,
      { :comment_count => :comments_count },
      { :description => :markeddown_description },
      { :description_plain => :description },
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

  def assign_short_id_and_score
    self.short_id = ShortId.new(self.class).generate
    self.score ||= 1 # tests are allowed to fake out the score
  end

  def calculated_hotness
    # take each tag's hotness modifier into effect, and give a slight bump to
    # stories submitted by the author
    base = self.tags.sum(:hotness_mod) + (self.user_is_author? && self.url.present? ? 0.25 : 0.0)

    # give a story's comment votes some weight, ignoring submitter's comments
    sum_expression = base < 0 ? "flags * -0.5" : "score + 1"
    cpoints = self.merged_comments.where.not(user_id: self.user_id).sum(sum_expression).to_f * 0.5

    # mix in any stories this one cannibalized
    cpoints += self.merged_stories.map(&:score).inject(&:+).to_f

    # if a story has many comments but few votes, it's probably a bad story, so
    # cap the comment points at the number of upvotes
    upvotes = self.score + self.flags
    if cpoints > upvotes
      cpoints = upvotes
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
    !is_gone? || (user && (user.is_moderator? || user.id == self.user_id))
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
    return false if self.is_moderated?

    self.tags.each {|t| return false if t.privileged? }
    return true
  end

  # this has to happen just before save rather than in tags_a= because we need
  # to have a valid user_id; remember it fills .taggings, not .tags
  def check_tags
    u = self.editor || self.user

    if u && u.is_new? &&
       (unpermitted = self.taggings.filter {|t| !t.tag.permit_by_new_users? }).any?
      tags = unpermitted.map {|t| t.tag.tag }.to_sentence
      errors.add :base, <<-EXPLANATION
        New users can't submit stories with the tag(s) #{tags}
        because they're for meta discussion or prone to off-topic stories.
        If a tag is appropriate for the story, leaving it off to skirt this
        restriction can earn a ban.
      EXPLANATION
      ModNote.tattle_on_new_user_tagging!(self)
      return
    end

    self.taggings.each do |t|
      if !t.tag.valid_for?(u)
        raise "#{u.username} does not have permission to use privileged tag #{t.tag.tag}"
      elsif !t.tag.active? && t.new_record? && !t.marked_for_destruction?
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

  def description_or_story_text(chars = 0)
    s = if self.description.present?
      self.markeddown_description.gsub(/<[^>]*>/, "")
    else
      self.story_text && self.story_text.body
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

  # TODO: race condition: if two votes arrive at the same time, the second one
  # won't take the first's score change into effect for calculated_hotness
  def update_score_and_recalculate!(score_delta, flag_delta)
    self.score += score_delta
    self.flags += flag_delta
    Story.connection.execute <<~SQL
      UPDATE stories SET
        score = (select coalesce(sum(vote), 0) from votes where story_id = stories.id and comment_id is null),
        flags = (select count(*) from votes where story_id = stories.id and comment_id is null and vote = -1),
        hotness = #{self.calculated_hotness}
      WHERE id = #{self.id.to_i}
    SQL
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

  def is_flaggable?
    if self.created_at && self.score > FLAGGABLE_MIN_SCORE
      Time.current - self.created_at <= FLAGGABLE_DAYS.days
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
    is_deleted? || (self.user.is_banned? && score < 0)
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

    m.action = all_changes.map {|k, v|
      if k == "is_deleted" && self.is_deleted?
        "deleted story"
      elsif k == "is_deleted" && !self.is_deleted?
        "undeleted story"
      elsif k == "merged_story_id"
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
    Comment.where(story_id: Story.select(:id).where(merged_story_id: self.id)
      .where('merged_story_id is not null') + [self.id])
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

  def short_id_path
    Rails.application.routes.url_helpers.root_path + "s/#{self.short_id}"
  end

  def short_id_url
    Rails.application.root_url + "s/#{self.short_id}"
  end

  def show_score_to_user?(u)
    return true if u && u.is_moderator?
    # cast nil to 0, only show score if user hasn't flagged
    (!vote || vote[:vote].to_i >= 0)
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
    self[:title] = t.to_s.strip.gsub(/[\.,;:!]*$/, '')
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
    self.update_column :comments_count, (comments.count {|c| !c.is_gone? })
    self.update_merged_into_story_comments
    self.recalculate_hotness!
  end

  def update_merged_into_story_comments
    if self.merged_into_story
      self.merged_into_story.update_comments_count!
    end
  end

  # disincentivize content marketers by not appearing to be a source of
  # significant traffic, but do show referrer a few times so authors can find
  # their way back
  def send_referrer?
    self.created_at && self.created_at <= 1.hour && self.merged_story_id.nil?
  end

  def set_domain(match)
    name = match ? match[:domain].sub(/^www\d*\./, '') : nil
    self.domain = name ? Domain.where(domain: name).first_or_initialize : nil
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
    set_domain(match)

    # strip out tracking query params
    if (match = u.match(/\A([^\?]+)\?(.+)\z/))
      params = match[2].split(/[&\?]/)
      # utm_ is google and many others; sk is medium
      params.reject! {|p|
        p.match(/^utm_(source|medium|campaign|term|content|referrer)=|^sk=|^gclid=|^fbclid=/x)
      }
      u = match[1] << (params.any?? "?" << params.join("&") : "")
    end

    super(u)
  end

  def url_is_editable_by_user?(user)
    if self.new_record?
      true
    elsif user && user.is_moderator?
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
          (Vote::ALL_STORY_REASONS[k] || k) +
          (user && user.is_moderator? ? " (#{r_whos[k].join(', ')})" : "")
      end
    }.join(", ")
  end

  def fetched_attributes_html
    converted = @fetched_response.body.force_encoding('utf-8')
    parsed = Nokogiri::HTML(converted.to_s)

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

    # strip off common GitHub site + repo owner
    @fetched_attributes[:title].sub!(/GitHub - [a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}\//i, '')

    # attempt to get the canonical url if it can be parsed,
    # if it is not the domain root path, and if it
    # responds to GET with a 200-level code
    begin
      cu = canonical_target(parsed)
      @fetched_attributes[:url] = cu if valid_canonical_uri?(cu)
    rescue
    end

    @fetched_attributes
  end

  def fetched_attributes_pdf
    return @fetched_attributes = {} if @fetched_response.body.length >= 5.megabytes

    # pdf-reader only accepts a stream or filename
    pdf_stream = StringIO.new(@fetched_response.body)
    pdf = PDF::Reader.new(pdf_stream)

    title = pdf.info[:Title]

    @fetched_attributes[:title] = title
    @fetched_attributes
  end

  def fetched_attributes
    return @fetched_attributes if @fetched_attributes

    @fetched_attributes = {
      :url => self.url,
      :title => "",
    }

    # security: do not connect to arbitrary user-submitted ports
    return @fetched_attributes if @url_port

    begin
      # if we haven't had a test inject a response into us
      if !@fetched_response
        s = Sponge.new
        s.timeout = 3
        # User submitted URLs may have an incorrect https certificate, but we
        # don't want to fail the retrieval for this. Security risk is minimal.
        s.ssl_verify = false
        headers = {
          "User-agent" => "#{Rails.application.domain} for #{fetching_ip}",
          "Referer" => Rails.application.domain,
        }
        res = s.fetch(url, :get, nil, nil, headers, 3)
        @fetched_response = res
      end

      case @fetched_response["content-type"]
      when /pdf/
        return fetched_attributes_pdf
      else
        return fetched_attributes_html
      end
    rescue
      return @fetched_attributes
    end
  end

private

  def valid_canonical_uri?(url)
    ucu = URI.parse(url)
    new_page = ucu &&
               ucu.scheme.present? &&
               ucu.host.present? &&
               ucu.path != "/"

    return false unless new_page

    res = Sponge.new.fetch(url)

    res.code.to_s =~ /\A2.*\Z/
  end

  def canonical_target(parsed)
    parsed.at_css("link[rel='canonical']").attributes["href"].text
  end
end
