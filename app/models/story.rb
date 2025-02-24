# typed: false

class Story < ApplicationRecord
  belongs_to :user
  belongs_to :domain, optional: true, counter_cache: true
  belongs_to :origin, optional: true, counter_cache: true
  belongs_to :merged_into_story,
    class_name: "Story",
    counter_cache: :stories_count,
    foreign_key: "merged_story_id",
    inverse_of: :merged_stories,
    optional: true
  has_many :merged_stories,
    class_name: "Story",
    foreign_key: "merged_story_id",
    inverse_of: :merged_into_story,
    dependent: :nullify
  has_many :taggings,
    autosave: true,
    dependent: :destroy
  has_many :suggested_taggings, dependent: :destroy
  has_many :suggested_tags, source: :story, through: :suggested_taggings, dependent: :destroy
  has_many :suggested_titles, dependent: :destroy
  has_many :suggested_tagging_times,
    -> { group(:tag_id).select("count(*) as times, tag_id").order(times: :desc) },
    class_name: "SuggestedTagging",
    inverse_of: :story
  has_many :suggested_title_times,
    -> { group(:title).select("count(*) as times, title").order(times: :desc) },
    class_name: "SuggestedTitle",
    inverse_of: :story
  has_many :comments,
    inverse_of: :story,
    dependent: :destroy
  has_many :tags, -> { order("tags.is_media desc, tags.tag") }, through: :taggings
  has_many :votes, -> { where(comment_id: nil) }, inverse_of: :story
  has_many :voters, -> { where("votes.comment_id" => nil) },
    through: :votes,
    source: :user
  has_many :hidings, class_name: "HiddenStory", inverse_of: :story, dependent: :destroy
  has_many :savings, class_name: "SavedStory", inverse_of: :story, dependent: :destroy
  has_one :story_text, foreign_key: :id, dependent: :destroy, inverse_of: :story
  has_many :links, inverse_of: :from_story, dependent: :destroy
  has_many :incoming_links,
    class_name: "Link",
    inverse_of: :to_story,
    dependent: :destroy

  scope :base, ->(user, unmerged: true) {
    q = includes(:hidings, :story_text, :user).not_deleted(user).mod_preload?(user)
    q = q.unmerged if unmerged
    q
  }
  scope :for_presentation, -> {
    includes(:domain, :origin, :hidings, :user, :tags, taggings: :tag)
  }
  scope :mod_preload?, ->(user) {
    user.try(:is_moderator?) ? preload(:suggested_taggings, :suggested_titles) : all
  }
  scope :deleted, -> { where(is_deleted: true) }
  scope :not_deleted, ->(user) {
    user.try(:is_moderator?) ? all : where(is_deleted: false).or(where(user_id: user.try(:id).to_i))
  }
  scope :unmerged, -> { where(merged_story_id: nil) }
  scope :positive_ranked, -> { where("score >= 0") }
  scope :low_scoring, ->(max = 5) { where("score < ?", max) }
  scope :front_page, -> { hottest.limit(StoriesPaginator::STORIES_PER_PAGE) }
  scope :hottest, ->(user = nil, exclude_tags = nil) {
    base(user).not_hidden_by(user)
      .filter_tags(exclude_tags || [])
      .positive_ranked
      .order(:hotness)
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
          .where(tag_filters: {user_id: user})
          .select(:story_id).arel
      )
    )
  }
  scope :hidden_by, ->(user) {
    user.nil? ? none : joins(:hidings).merge(HiddenStory.by(user))
  }
  scope :not_hidden_by, ->(user) {
    user.nil? ? all : where.not(
      HiddenStory.select("TRUE")
        .where(Arel.sql("hidden_stories.story_id = stories.id"))
        .by(user)
        .arel
        .exists
    )
  }
  scope :saved_by, ->(user) {
    user.nil? ? none : joins(:savings).merge(SavedStory.by(user))
  }
  scope :to_mastodon, -> {
    hottest(nil, Tag.where(tag: "meta").ids)
      .where(mastodon_id: nil)
      .where("score >= 2")
      .where("created_at >= ?", 2.days.ago)
      .limit(10)
  }

  validates :title, length: {in: 3..150}, presence: true
  validates :description, length: {maximum: 65_535}
  validates :url, length: {maximum: 250, allow_nil: true}
  validates :short_id, presence: true, length: {maximum: 6}
  validates :markeddown_description, length: {maximum: 16_777_215, allow_nil: true}
  validates :mastodon_id, length: {maximum: 25, allow_nil: true}
  validates :twitter_id, length: {maximum: 20, allow_nil: true}
  validates :is_deleted, :is_moderated, :user_is_author, :user_is_following, inclusion: {in: [true, false]}
  validates :score, :flags, :hotness, :comments_count, presence: true
  validates :normalized_url, length: {maximum: 255, allow_nil: true}
  validates :last_edited_at, presence: true

  validates_each :merged_story_id do |record, _attr, value|
    if value.to_i == record.id
      record.errors.add(:merge_story_short_id, "id cannot be itself.")
    end
  end

  COMMENTABLE_DAYS = 90
  FLAGGABLE_DAYS = 14
  DELETEABLE_DAYS = FLAGGABLE_DAYS * 2

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

  # Dingbats, emoji, and other graphics https://www.unicode.org/charts/
  GRAPHICS_RE = /[\u{0000}-\u{001F}\u{2190}\u{2192}-\u{27BF}\u{1F000}-\u{1F9FF}]/

  attr_accessor :current_vote, :editing_from_suggestions, :editor, :fetching_ip,
    :is_hidden_by_cur_user, :latest_comment_id,
    :is_saved_by_cur_user, :moderation_reason, :previewing, :tags_was
  attr_writer :fetched_response

  before_validation :assign_initial_attributes, on: :create
  before_save :log_moderation
  before_save :fix_bogus_chars
  after_create :mark_submitter, :record_initial_upvote
  after_save :recreate_links, :update_cached_columns, :update_story_text

  validate do
    if url.present?
      already_posted_recently?
      check_not_banned_domain
      check_not_banned_origin
      check_not_new_domain_from_new_user
      # This would probably have a too-high false-positive rate, I want to have approvals first.
      # check_not_new_origin_from_new_user
      check_not_brigading
      check_not_pushcx_stream
      errors.add(:url, "is not valid") unless url.match(Utils::URL_RE)
    elsif description.to_s.strip == ""
      errors.add(:description, "must contain text if no URL posted")
    end

    if title.starts_with?("Ask") && tags.map(&:tag).include?("ask")
      errors.add(:title, " starting 'Ask #{Rails.application.name}' or similar is redundant " \
                          "with the ask tag.")
    end
    if title.match(GRAPHICS_RE)
      errors.add(:title, " may not contain graphic codepoints")
    end
    if title == title.upcase
      errors.add(:title, " doesn't need to scream, ASCII has supported lowercase since June 17, 1963.")
    end

    if !errors.any? && url.blank?
      self.user_is_author = true
    end

    check_tags
  end

  def self./(short_id)
    find_by! short_id:
  end

  def accepting_comments?
    !is_gone? &&
      !previewing &&
      (new_record? || created_at.after?(COMMENTABLE_DAYS.days.ago))
  end

  def already_posted_recently?
    return false unless url.present? && new_record?

    if most_recent_similar&.is_recent?
      errors.add(:url, "has already been submitted within the past #{RECENT_DAYS} days")
      true
    elsif user&.is_new? && most_recent_similar
      errors.add(:url, "cannot be resubmitted by new users")
      true
    else
      false
    end
  end

  def check_not_new_domain_from_new_user
    return unless url.present? && new_record? && domain

    if user&.is_new? && domain.stories.not_deleted(nil).count == 0
      ModNote.tattle_on_story_domain!(self, "new user with new")
      errors.add :url, <<-EXPLANATION
        is an unseen domain from a new user. We restrict this to discourage
        self-promotion and give you time to learn about topicality. Skirting
        this with a URL shortener or tweet or something will probably earn a ban.
      EXPLANATION
    end
  end

  def check_not_new_origin_from_new_user
    return unless url.present? && new_record? && domain && origin

    if user&.is_new? && origin.stories.not_deleted(nil).count == 0
      ModNote.tattle_on_story_origin!(self, "new user with new")
      errors.add :url, <<-EXPLANATION
        is from a domain that we know has multiple authors, like GitHub. We haven't
        seen links from this origin '#{origin.identifier}' before.
        We restrict new users from posting such links to discourage self-promotion and give
        you time to learn about topicality. Skirting this with a URL shortener or tweet or something
        will probably earn a ban.
      EXPLANATION
    end
  end

  def check_not_banned_domain
    return unless url.present? && new_record? && domain

    if domain.banned?
      ModNote.tattle_on_story_domain!(self, "banned")
      errors.add(:url, "is from banned domain #{domain.domain}: #{domain.banned_reason}")
    end
  end

  def check_not_banned_origin
    return unless url.present? && new_record? && origin

    if origin.banned?
      ModNote.tattle_on_story_origin!(self, "banned")
      errors.add(:url, "is from banned origin #{origin.identifier}: #{origin.banned_reason}")
    end
  end

  def check_not_brigading
    return if url.blank? || !new_record? || !(
      url.match?(%r{^https://bitbucket.org/[^/]+/[^/]+/(issues|pull-requests)/}) ||
      url.match?(%r{^https://bugs.launchpad.net/[^/]+/\+bug/}) ||
      url.match?(%r{^https://chiselapp.com/user/[^/]+/repository/[^/]+/tktview/}) ||
      url.match?(%r{^https://codeberg.org/[^/]+/[^/]+/(issues|pulls)/}) ||
      url.match?(%r{^https://github.com/[^/]+/[^/]+/(discussions|issues|pull)/}) ||
      url.match?(%r{^https://gitlab.com/.+/(issues|merge_requests)/}) ||
      url.match?(%r{^https://savannah.gnu.org/bugs/}) ||
      url.match?(%r{^https://sourceforge.net/p/[^/]+/(support|tickets)/})
    )

    ModNote.tattle_on_brigading!(self)
    errors.add :url, <<~EXPLANATION
      is to a project's bug tracker or discussions; see the Guidelines on brigading. It's bad for
      projects when we dump 100k+ people into their community spaces, and Lobsters doesn't have good
      threads when we're dropped without context into the middle of a controvery. If you weren't
      trying to brigade the site into a fight you are involved in: find an overview, preferably from
      a neutral third party. If you were trying to do that: don't.
    EXPLANATION
  end

  def check_not_pushcx_stream
    return unless url.present? && new_record? &&
      url.start_with?("https://push.cx/stream", "https://twitch.tv/pushcx")
    errors.add(:url, "is too much meta, we don't need it twice every week. Details: https://lobste.rs/c/skuxo9")
  end

  def comments_closing_soon?
    created_at && (created_at - 1.hour).before?(Story::COMMENTABLE_DAYS.days.ago)
  end

  # current_vote is the vote loaded for the currently-viewing user
  def current_flagged?
    current_vote.try(:[], :vote) == -1
  end

  def current_upvoted?
    current_vote.try(:[], :vote) == 1
  end

  def negativity_class
    @neg ||= score - flags
    if @neg <= -5
      "negative_5"
    elsif @neg <= -3
      "negative_3"
    elsif @neg <= -1
      "negative_1"
    else
      ""
    end
  end

  # all stories with similar urls
  def self.find_similar_by_url(url)
    # if a previous submission was moderated, return it to block it from being
    # submitted again
    Story.where(normalized_url: Utils.normalize(url))
      .where("is_deleted = ? OR is_moderated = ?", false, true)
      .order(id: :desc)
  end

  # doesn't include deleted/moderated/merged stories
  def similar_stories
    return Story.none if url.blank?

    @_similar_stories ||= Story.find_similar_by_url(url).order(id: :desc)
    # do not include this story itself or any story merged into it
    if id?
      @_similar_stories = @_similar_stories.where.not(id: id)
        .where("merged_story_id is null or merged_story_id != ?", id)
    end
    # do not include the story this one is merged into
    if merged_story_id?
      @_similar_stories = @_similar_stories.where.not(id: merged_story_id)
    end
    @_similar_stories
  end

  def public_similar_stories(user)
    @_public_similar_stories ||= similar_stories.base(user)
  end

  def is_resubmit?
    !already_posted_recently? && similar_stories.any?
  end

  def most_recent_similar
    similar_stories.first
  end

  def self.recalculate_all_hotnesses!
    # do the front page first, since find_each can't take an order
    Story.order(id: :desc).limit(100).each(&:update_cached_columns)
    Story.find_each(&:update_cached_columns)
    true
  end

  def archiveorg_url
    # This will redirect to the latest version they have
    "https://web.archive.org/web/3/#{CGI.escape(url)}"
  end

  def archivetoday_url
    "https://archive.today/#{CGI.escape(url)}"
  end

  def ghost_url
    "https://ghostarchive.org/search?term=#{CGI.escape(url)}"
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
      {comment_count: :comments_count},
      {description: :markeddown_description},
      {description_plain: :description},
      :comments_url,
      {submitter_user: user.username},
      :user_is_author,
      {tags: tags.map(&:tag).sort}
    ]

    if options && options[:with_comments]
      h.push(comments: options[:with_comments])
    end

    js = {}
    h.each do |k|
      if k.is_a?(Symbol)
        js[k] = send(k)
      elsif k.is_a?(Hash)
        js[k.keys.first] = if k.values.first.is_a?(Symbol)
          send(k.values.first)
        else
          k.values.first
        end
      end
    end

    js
  end

  def assign_initial_attributes
    self.short_id = ShortId.new(self.class).generate
    self.score ||= 1 # tests are allowed to fake out the score
    self.hotness = calculated_hotness
    self.last_edited_at = Time.current
  end

  def calculated_hotness
    # take each tag's hotness modifier into effect, and give a slight bump to
    # stories submitted by the author
    base = tags.sum(:hotness_mod) + ((user_is_author? && url.present?) ? 0.25 : 0.0)

    # give a story's comment votes some weight, ignoring submitter's comments
    cpoints = if base < 0
      0
    else
      merged_comments.where.not(user_id: user_id).sum("comments.score + 1").to_f * 0.5
    end

    # mix in any stories this one cannibalized
    cpoints += merged_stories.map(&:score).inject(&:+).to_f

    # if a story has many comments but few votes, it's probably a bad story, so
    # cap the comment points at the number of upvotes
    cpoints = [self.score, cpoints].min

    # don't immediately kill stories at 0 by bumping up score by one
    order = Math.log([(score + 1).abs + cpoints, 1].max, 10)
    sign = if score > 0
      1
    elsif score < 0
      -1
    else
      0
    end

    -((order * sign) + base + ((created_at || Time.current).to_f / HOTNESS_WINDOW)).round(7)
  end

  def can_be_seen_by_user?(user)
    !is_gone? || (user && (user.is_moderator? || user.id == user_id))
  end

  def can_have_images?
    # doesn't test self.editor so a user can't trick a mod into editing a
    # story to enable an image
    user.try(:is_moderator?)
  end

  def can_have_suggestions_from_user?(user)
    if !user || (user.id == user_id) || !user.can_offer_suggestions?
      return false
    end
    return false if is_moderated?

    tags.each { |t| return false if t.privileged? }
    true
  end

  # this has to happen just before save because it depends on user/editor
  def check_tags
    u = editor || user

    if u&.is_new? &&
        (unpermitted = tags.select { |t| t.permit_by_new_users == false }).any?
      tags_str = unpermitted.map(&:tag).to_sentence
      errors.add :base, <<-EXPLANATION
        New users can't submit stories with the tag(s) #{tags_str}
        because they're for meta discussion or prone to off-topic stories.
        If a tag is appropriate for the story, leaving it off to skirt this
        restriction can earn a ban.
      EXPLANATION
      ModNote.tattle_on_new_user_tagging!(self)
      return
    end

    tags.each do |t|
      if !t.can_be_applied_by?(u) && t.privileged?
        raise "#{u.username} does not have permission to use privileged tag #{t.tag}"
      elsif !t.can_be_applied_by?(u) && !t.permit_by_new_users?
        errors.add(:base, "New users can't submit #{t.tag} stories, please wait. " \
          "If the tag is appropriate, leaving it off to skirt this restriction is a bad idea.")
        ModNote.tattle_on_story_domain!(self, "new user with protected tags")
        raise "#{u.username} is too new to use tag #{t.tag}"
      end
    end

    if tags.reject { |t| t.is_media? }.empty?
      errors.add(:base, "Must have at least one non-media (PDF, video) " \
        "tag.  If no tags apply to your content, it probably doesn't " \
        "belong here.")
    end
  end

  def comments_path
    "#{short_id_path}/#{title_as_url}"
  end

  def comments_url
    "#{short_id_url}/#{title_as_url}"
  end

  def description=(desc)
    self[:description] = desc.to_s.rstrip
    self.markeddown_description = generated_markeddown_description
  end

  def description_or_story_text(chars = 0)
    s = if description.present?
      markeddown_description.gsub(/<[^>]*>/, "")
    else
      story_text&.body
    end

    if chars > 0 && s.to_s.length > chars
      # remove last truncated word
      s = s.to_s[0, chars].gsub(/ [^ ]*\z/, "")
    end

    HtmlEncoder.decode(s.to_s)
  end

  def domain_search_url
    "/search?order=newest&q=domain:#{domain}"
  end

  def fix_bogus_chars
    # this is needlessly complicated to work around character encoding issues
    # that arise when doing just self.title.to_s.gsub(160.chr, "")
    self.title = title.to_s.chars.map { |chr|
      if chr.ord == 160
        " "
      else
        chr
      end
    }.join("")

    true
  end

  def generated_markeddown_description
    Markdowner.to_html(description, allow_images: can_have_images?)
  end

  # TODO: race condition: if two votes arrive at the same time, the second one
  # won't take the first's score change into effect for calculated_hotness
  def update_score_and_recalculate!(score_delta, flag_delta)
    self.score += score_delta
    self.flags += flag_delta
    Story.connection.execute <<~SQL
      UPDATE stories SET
        score = (select count(*) from votes where story_id = stories.id and comment_id is null and vote = 1) -
        -- subtract number of hidings where hider flagged AND didn't comment (comment voting is ignored)
        (
          select count(*) from hidden_stories hiding
          where
            story_id = #{id.to_i}
            and hiding.created_at >= str_to_date('#{(created_at - FLAGGABLE_DAYS.days).utc.iso8601}', '%Y-%m-%dT%H:%i:%sZ')
            and exists (    -- user flagged
              select 1 from votes where hiding.user_id = votes.user_id and votes.story_id = stories.id and vote = -1
            )
            and not exists ( -- user didn't comment
              select 1 from comments where hiding.user_id = comments.user_id and comments.story_id = stories.id
            )
        ),
        flags = (select count(*) from votes where story_id = stories.id and comment_id is null and vote = -1),
        hotness = #{calculated_hotness}
      WHERE id = #{id.to_i}
    SQL
  end

  def has_suggestions?
    suggested_taggings.any? || suggested_titles.any?
  end

  def hider_count
    @hider_count ||= HiddenStory.where(story_id: id).count
  end

  def disownable_by_user?(user)
    user && user.id == user_id && created_at < DELETEABLE_DAYS.days.ago
  end

  def is_flaggable?
    if created_at && self.score > FLAGGABLE_MIN_SCORE
      Time.current - created_at <= FLAGGABLE_DAYS.days
    else
      false
    end
  end

  def is_editable_by_user?(user)
    return false if user.nil? || user.new_record? # assumption: cabinet view

    if user&.id == user_id
      if is_moderated?
        false
      else
        created_at.after?(MAX_EDIT_MINS.minutes.ago)
      end
    else
      false
    end
  end

  def is_gone?
    is_deleted? || (user.is_banned? && score < 0)
  end

  def is_hidden_by_user?(user)
    !!HiddenStory.find_by(user_id: user.id, story_id: id)
  end

  def is_recent?
    created_at >= RECENT_DAYS.days.ago
  end

  def is_saved_by_user?(user)
    !!SavedStory.find_by(user_id: user.id, story_id: id)
  end

  def is_unavailable
    !unavailable_at.nil?
  end

  def is_unavailable=(what)
    self.unavailable_at = ((what.to_i == 1 && !is_unavailable) ? Time.current : nil)
  end

  def is_undeletable_by_user?(user)
    if user&.is_moderator?
      true
    elsif user && user.id == user_id && !is_moderated?
      true
    else
      false
    end
  end

  def log_moderation
    if new_record? ||
        (!editing_from_suggestions && (!editor || editor.id == user_id))
      return
    end

    all_changes = changes.merge(tag_changes)
    all_changes.delete("normalized_url")
    all_changes.delete("unavailable_at")
    all_changes.delete("last_edited_at")

    if !all_changes.any?
      return
    end

    m = Moderation.new
    if editing_from_suggestions
      m.is_from_suggestions = true
    else
      m.moderator_user_id = editor.try(:id)
    end
    m.story_id = id

    m.action = all_changes.map { |k, v|
      if k == "is_deleted" && is_deleted?
        "deleted story"
      elsif k == "is_deleted" && !is_deleted?
        "undeleted story"
      elsif k == "merged_story_id"
        if v[1]
          "merged into #{merged_into_story.short_id} " \
            "(#{merged_into_story.title})"
        else
          "unmerged from another story"
        end
      else
        "changed #{k} from #{v[0].inspect} to #{v[1].inspect}"
      end
    }.join(", ")

    m.reason = moderation_reason
    m.save!

    self.is_moderated = true
  end

  def mailing_list_message_id
    "story.#{short_id}.#{created_at.to_i}@#{Rails.application.domain}"
  end

  def mark_submitter
    Keystore.increment_value_for("user:#{user_id}:stories_submitted")
  end

  # unordered, use Comment.thread_sorted_comments for presenting threads
  def merged_comments
    return Comment.none unless id # unsaved Stories have no comments

    Comment.joins(:story)
      .where(story: {merged_story_id: id})
      .or(Comment.where(story_id: id))
  end

  def merge_story_short_id=(sid)
    self.merged_story_id = sid.present? ? Story.where(short_id: sid).pick(:id) : nil
  end

  def merge_story_short_id
    merged_story_id ? merged_into_story.try(:short_id) : nil
  end

  def record_initial_upvote
    Vote.vote_thusly_on_story_or_comment_for_user_because(1, id, nil, user_id, nil, false)
  end

  def short_id_path
    Rails.application.routes.url_helpers.root_path + "s/#{short_id}"
  end

  def short_id_url
    Rails.application.root_url + "s/#{short_id}"
  end

  def show_score_to_user?(u)
    u&.is_moderator? || !current_flagged?
  end

  def tag_changes
    # 'tags_was' is bad grammar but is named to mirror ActiveModel::Dirty's convention of providing
    # a 'attribute_was' reader. The AR associations API is pretty broad, so rather than try to
    # override all the methods to maintain state, this exception should prompt you to only use
    # the tags= method. See StoriesController#update for an example.
    raise "Controller didn't save tags_was for edit logging" if tags_was.nil?

    old_tag_names = tags_was.map(&:tag).join(" ")
    new_tag_names = tags.map(&:tag).join(" ")

    if old_tag_names == new_tag_names
      {}
    else
      {"tags" => [old_tag_names, new_tag_names]}
    end
  end

  def save_suggested_tags_for_user!(new_tag_names_a, user)
    suggested_taggings.where(user_id: user.id).destroy_all

    new_tags = Tag
      .active
      .where(tag: new_tag_names_a.uniq.compact_blank)
      .map { |t| {user: user, tag: t} }
    suggested_taggings.create!(new_tags)

    # if enough users voted on the same set of replacement tags, do it
    tag_votes = {}
    suggested_taggings.group_by(&:user_id).each do |_u, stg|
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

    if final_tags.any? && (final_tags.sort != tags.map(&:tag).sort)
      # Rails.logger.info "[s#{id}] promoting suggested tags " \
      #  "#{final_tags.inspect} instead of #{tags.map(&:tag).inspect}"
      self.editor = nil
      self.editing_from_suggestions = true
      self.moderation_reason = "Automatically changed from user suggestions"
      self.tags_was = tags.to_a
      self.tags = Tag.where(tag: final_tags)
      if !save
        # Rails.logger.error "[s#{id}] failed auto promoting: " << errors.inspect
      end
    end
  end

  def save_suggested_title_for_user!(title, user)
    st = suggested_titles.find_by(user_id: user.id)
    if !st
      st = suggested_titles.build
      st.user_id = user.id
    end
    st.title = title
    st.save!

    # if enough users voted on the same exact title, save it
    title_votes = {}
    suggested_titles.each do |s|
      title_votes[s.title] ||= 0
      title_votes[s.title] += 1
    end

    title_votes.sort_by { |_k, v| v }.reverse_each do |kv|
      if kv[1] >= SUGGESTION_QUORUM
        # Rails.logger.info "[s#{id}] promoting suggested title " \
        #   "#{kv[0].inspect} instead of #{self.title.inspect}"
        self.editor = nil
        self.editing_from_suggestions = true
        self.moderation_reason = "Automatically changed from user suggestions"
        self.title = kv[0]
        self.tags_was = tags.to_a
        if !save
          # Rails.logger.error "[s#{id}] failed auto promoting: " << errors.inspect
        end

        break
      end
    end
  end

  def title=(t)
    # change unicode whitespace characters into real spaces
    self[:title] = t.to_s.strip.gsub(/[\.,;:!]*$/, "")
  end

  def title_as_url
    max_len = 35
    wl = 0
    words = []

    title
      .parameterize
      .gsub(/[^a-z0-9]/, "_")
      .split("_")
      .reject { |z| TITLE_DROP_WORDS.include?(z) }
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

    words.join("_").gsub("_-_", "-")
  end

  def to_param
    short_id
  end

  def update_availability
    if is_unavailable && !unavailable_at
      self.unavailable_at = Time.current
    elsif unavailable_at && !is_unavailable
      self.unavailable_at = nil
    end
  end

  # this is less evil than it looks because commonmark produces consistent html:
  # <a href="http://example.com/" rel="ugc">example</a>
  def parsed_links
    if markeddown_description.blank?
      []
    else
      markeddown_description
        .scan(/<a href="([^"]+)" .*>([^<]+)<\/a>/)
        .map { |url, title|
          Link.new({
            from_story_id: id,
            url: url,
            title: (url == title) ? nil : title
          })
        }.compact
    end +
      if url.blank?
        []
      else
        [Link.new({
          from_story_id: id,
          url: url,
          title: title
        })]
      end
  end

  def recreate_links
    Link.recreate_from_story!(self) if saved_change_to_attribute?(:url) || saved_change_to_attribute?(:description)
  end

  def update_cached_columns
    update_column :comments_count, merged_comments.active.count
    merged_into_story&.update_cached_columns

    update_column :hotness, calculated_hotness
  end

  def update_story_text
    return unless saved_change_to_attribute?(:title) || saved_change_to_attribute?(:description)

    # story_text created by cron job, so ignore missing story_text
    story_text.try(:update!, title: title, description: description)
  end

  # disincentivize content marketers by not appearing to be a source of
  # significant traffic, but do show referrer a few times so authors can find
  # their way back
  def send_referrer?
    created_at && created_at <= 1.hour && merged_story_id.nil?
  end

  def set_domain_and_origin(domain_name)
    domain_name&.sub!(/\Awww\d*\.(.+?\..+)/, '\1') # remove www\d* from domain if the url is not like www10.org
    if domain_name.present?
      self.domain = Domain.where(domain: domain_name).first_or_initialize
      self.origin = domain&.find_or_create_origin(url)
    else
      self.domain = nil
      self.origin = nil
    end
  end

  def url=(u)
    return if u.blank?
    u = u.strip

    # strip out tracking query params
    if (match = u.match(/\A([^\?]+)\?(.+)\z/))
      params = match[2].split(/[&\?]/)
      # utm_ is google and many others; sk is medium; si is youtube source id
      params.reject! { |p|
        p.match(/^utm_(source|medium|campaign|term|content|referrer)=|^sk=|^gclid=|^fbclid=|^linkId=|^si=|^trk=/x)
      }
      params.reject! { |p|
        if /^lobsters|^src=lobsters|^ref=lobsters/x.match?(p)
          ModNote.tattle_on_traffic_attribution!(self)
          true
        end
      }
      u = match[1] << (params.any? ? "?#{params.join("&")}" : "")
    end

    if (match = u.match(Utils::URL_RE))
      # remove well-known port for http and https if present
      @url_port = match[:port]
      if match[:protocol] == "http" && match[:port] == ":80" ||
          match[:protocol] == "https" && match[:port] == ":443"
        u = u[0...match.begin(3)] + u[match.end(3)..]
        @url_port = nil
      end
    end

    # set field
    super

    # set related fields
    self.normalized_url = Utils.normalize(u)
    set_domain_and_origin(match&.[](:domain))
  end

  def url_is_editable_by_user?(user)
    if new_record? # assumption: can only see it previewing a new story
      true
    elsif !is_moderated? && created_at.after?(MAX_EDIT_MINS.minutes.ago)
      true
    else
      user&.is_moderator?
    end
  end

  def url_or_comments_path
    url.presence || comments_path
  end

  def url_or_comments_url
    url.presence || comments_url
  end

  def vote_summary_for(user)
    r_counts = {}
    r_whos = {}
    votes.includes(user&.is_moderator? ? :user : nil).find_each do |v|
      next if v.vote == 0
      r_counts[v.reason.to_s] ||= 0
      r_counts[v.reason.to_s] += 1
      if user&.is_moderator?
        r_whos[v.reason.to_s] ||= []
        r_whos[v.reason.to_s].push v.user.username
      end
    end

    r_counts.keys.sort.map { |k|
      if k == ""
        "+#{r_counts[k]}"
      else
        "#{r_counts[k]} " +
          (Vote::ALL_STORY_REASONS[k] || k) +
          ((user && user.is_moderator?) ? " (#{r_whos[k].join(", ")})" : "")
      end
    }.join(", ")
  end

  def fetched_attributes_html
    converted = @fetched_response.body.force_encoding("utf-8")
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
          title[-site_name.length, site_name.length] == site_name
        title = title[0, title.length - site_name.length]

        # remove title/site name separator
        if / [ \-\|\u2013] $/.match?(title)
          title = title[0, title.length - 3]
        end
      end
    rescue
    end

    @fetched_attributes[:title] = title

    # strip off common GitHub site + repo owner
    @fetched_attributes[:title].sub!(/GitHub - [a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}\//i, "")

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
      url: url,
      title: ""
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
          "Referer" => Rails.application.domain
        }
        res = s.fetch(url, :get, nil, nil, headers, 3)
        @fetched_response = res
      end

      case @fetched_response["content-type"]
      when /pdf/
        fetched_attributes_pdf
      else
        fetched_attributes_html
      end
    rescue
      @fetched_attributes
    end
  end

  def self.title_maximum_length
    validators_on(:title)
      .find { |v| v.is_a? ActiveRecord::Validations::LengthValidator }
      .options[:maximum]
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
