require 'set'

class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :story,
             :inverse_of => :comments
  has_many :votes,
           :dependent => :delete_all
  belongs_to :parent_comment,
             :class_name => "Comment",
             :inverse_of => false,
             :optional => true
  has_one :moderation,
          :class_name => "Moderation",
          :inverse_of => :comment,
          :dependent => :destroy
  belongs_to :hat,
             :optional => true
  has_many :taggings, through: :story

  attr_accessor :current_vote, :previewing, :indent_level

  before_validation :on => :create do
    self.assign_short_id_and_score
    self.assign_initial_confidence
    self.assign_thread_id
  end
  after_create :record_initial_upvote, :mark_submitter, :deliver_reply_notifications,
               :deliver_mention_notifications, :log_hat_use
  after_destroy :unassign_votes

  scope :deleted, -> { where(is_deleted: true) }
  scope :not_deleted, -> { where(is_deleted: false) }
  scope :not_moderated, -> { where(is_moderated: false) }
  scope :active, -> { not_deleted.not_moderated }
  scope :accessible_to_user, ->(user) { user && user.is_moderator? ? all : active }
  scope :not_on_story_hidden_by, ->(user) {
    user ? where.not(
      HiddenStory.select('TRUE')
      .where(Arel.sql('hidden_stories.story_id = stories.id'))
      .by(user).arel.exists
    ) : where('true')
  }

  FLAGGABLE_DAYS = 7
  DELETEABLE_DAYS = FLAGGABLE_DAYS * 2

  # the lowest a score can go
  FLAGGABLE_MIN_SCORE = -10

  # the score at which a comment should be collapsed
  COLLAPSE_SCORE = -5

  # after this many minutes old, a comment cannot be edited
  MAX_EDIT_MINS = (60 * 6)

  SCORE_RANGE_TO_HIDE = (-2 .. 4).freeze

  validates :short_id, length: { maximum: 10 }
  validates :user_id, presence: true
  validates :story_id, presence: true
  validates :markeddown_comment, length: { maximum: 16_777_215 }
  validates :comment, presence: { with: true, message: "cannot be empty." }

  validate do
    self.parent_comment && self.parent_comment.is_gone? &&
      errors.add(:base, "Comment was deleted by the author or a mod while you were writing.")

    (m = self.comment.to_s.strip.match(/\A(t)his([\.!])?$\z/i)) &&
      errors.add(:base, (m[1] == "T" ? "N" : "n") + "ope" + m[2].to_s)

    self.comment.to_s.strip.match(/\Atl;?dr.?$\z/i) &&
      errors.add(:base, "Wow!  A blue car!")

    self.comment.to_s.strip.match(/\A([[[:upper:]][[:punct:]]] )+[[[:upper:]][[:punct:]]]?$\z/) &&
      errors.add(:base, "D O N ' T")

    self.comment.to_s.strip.match(/\A(me too|nice)([\.!])?\z/i) &&
      errors.add(:base, "Please just upvote the parent post instead.")

    self.hat.present? && self.user.wearable_hats.exclude?(self.hat) &&
      errors.add(:hat, "not wearable by user")

    # .try so tests don't need to persist a story and user
    self.story.try(:accepting_comments?) ||
      errors.add(:base, "Story is no longer accepting comments.")
  end

  def self.arrange_for_user(user)
    # This function is always used when presenting threads. The calling
    # controllers advance the user's ReadRibbon, which may reduce the number
    # of ReplyingComments, invalidating the User.unread_replies_count cache.
    # The controller clearing that cache on every view of any thread would be
    # wasteful because users read many more threads than they participate in,
    # the controller making an extra loop over all comments would be wasteful,
    # so this does a couple checks (without replicating all the predicates in
    # replying_comments view, which would be brittle) and may clear the cache.
    #
    # This whole function should be done in the DB using a common-table
    # expression. When that happens the cache clear probably needs to move up
    # to the controller, which means extra clears, but that's probably a win
    # because this function is the site's core functionality and it's
    # expensive in both CPU + redundant RAM for the web workers.
    clear_replies_cache = false

    parents = self.order(
      Arel.sql("comments.score < 0 ASC, comments.confidence DESC")
    )
      .group_by(&:parent_comment_id)

    # top-down list of comments, regardless of indent level
    ordered = []

    ancestors = [nil] # nil sentinel so indent_level starts at 1 without add op.
    subtree = parents[nil]

    while subtree
      if (node = subtree.shift)
        children = parents[node.id]

        clear_replies_cache = true if user && node.user_id == user.id

        # for deleted comments, if they have no children, they can be removed
        # from the tree.  otherwise they have to stay and a "[deleted]" stub
        # will be shown
        if node.is_gone? && # deleted or moderated
           !children.present? && # don't have child comments
           (!user || (!user.is_moderator? && node.user_id != user.id))
          # admins and authors should be able to see their deleted comments
          next
        end

        node.indent_level = ancestors.length
        ordered << node

        # no children to recurse
        next unless children

        # drill down a level
        ancestors << subtree
        subtree = children
      else
        # climb back out
        subtree = ancestors.pop
      end
    end

    Rails.cache.delete("user:#{user.id}:unread_replies") if clear_replies_cache

    ordered
  end

  def self.regenerate_markdown
    Comment.record_timestamps = false

    Comment.all.find_each do |c|
      c.markeddown_comment = c.generated_markeddown_comment
      c.save(:validate => false)
    end

    Comment.record_timestamps = true

    nil
  end

  def as_json(_options = {})
    h = [
      :short_id,
      :short_id_url,
      :created_at,
      :updated_at,
      :is_deleted,
      :is_moderated,
      :score,
      :flags,
      { :parent_comment => self.parent_comment && self.parent_comment.short_id },
      { :comment => (self.is_gone? ? "<em>#{self.gone_text}</em>" : :markeddown_comment) },
      { :comment_plain => (self.is_gone? ? self.gone_text : :comment) },
      :url,
      :indent_level,
      { :commenting_user => :user },
    ]

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

  def assign_initial_confidence
    self.confidence = self.calculated_confidence
  end

  def assign_short_id_and_score
    self.short_id = ShortId.new(self.class).generate
    self.score ||= 1 # tests are allowed to fake out the score
  end

  def assign_thread_id
    if self.parent_comment_id.present?
      self.thread_id = self.parent_comment.thread_id
    else
      self.thread_id = Keystore.incremented_value_for("thread_id")
    end
  end

  # http://evanmiller.org/how-not-to-sort-by-average-rating.html
  # https://github.com/reddit/reddit/blob/master/r2/r2/lib/db/_sorts.pyx
  def calculated_confidence
    n = (self.score + self.flags * 2).to_f
    return 0 if n == 0.0

    upvotes = self.score + self.flags
    z = 1.281551565545 # 80% confidence
    p = upvotes.to_f / n

    left = p + (1 / ((2.0 * n) * z * z))
    right = z * Math.sqrt((p * ((1.0 - p) / n)) + (z * (z / (4.0 * n * n))))
    under = 1.0 + ((1.0 / n) * z * z)

    return (left - right) / under
  end

  def comment=(com)
    self[:comment] = com.to_s.rstrip
    self.markeddown_comment = self.generated_markeddown_comment
  end

  def delete_for_user(user, reason = nil)
    Comment.record_timestamps = false

    self.is_deleted = true

    if user.is_moderator? && user.id != self.user_id
      self.is_moderated = true

      m = Moderation.new
      m.comment_id = self.id
      m.moderator_user_id = user.id
      m.action = "deleted comment"

      if reason.present?
        m.reason = reason
      end

      m.save

      User.update_counters self.user_id, karma: (self.votes.count * -2)
    end

    self.save(:validate => false)
    Comment.record_timestamps = true

    self.story.update_comments_count!
    self.user.refresh_counts!
  end

  def deliver_mention_notifications
    self.plaintext_comment.scan(/\B\@([\w\-]+)/).flatten.uniq.each do |mention|
      if (u = User.active.find_by(:username => mention))
        if u.id == self.user.id
          next
        end

        if u.email_mentions?
          begin
            EmailReply.mention(self, u).deliver_now
          rescue => e
            Rails.logger.error "error e-mailing #{u.email}: #{e}"
          end
        end

        if u.pushover_mentions?
          u.pushover!(
            :title => "#{Rails.application.name} mention by " <<
              "#{self.user.username} on #{self.story.title}",
            :message => self.plaintext_comment,
            :url => self.url,
            :url_title => "Reply to #{self.user.username}",
          )
        end
      end
    end
  end

  def users_following_thread
    users_following_thread = Set.new
    if self.user.id != self.story.user.id && self.story.user_is_following
      users_following_thread << self.story.user
    end

    if self.parent_comment_id &&
       (u = self.parent_comment.try(:user)) &&
       u.id != self.user.id &&
       u.is_active?
      users_following_thread << u
    end

    users_following_thread
  end

  def deliver_reply_notifications
    users_following_thread.each do |u|
      if u.email_replies?
        begin
          EmailReply.reply(self, u).deliver_now
        rescue => e
          Rails.logger.error "error e-mailing #{u.email}: #{e}"
        end
      end

      if u.pushover_replies?
        u.pushover!(
          :title => "#{Rails.application.name} reply from " <<
            "#{self.user.username} on #{self.story.title}",
          :message => self.plaintext_comment,
          :url => self.url,
          :url_title => "Reply to #{self.user.username}",
        )
      end
    end
  end

  def generated_markeddown_comment
    Markdowner.to_html(self.comment)
  end

  # TODO: race condition: if two votes arrive at the same time, the second one
  # won't take the first's score change into effect for calculated_confidence
  def update_score_and_recalculate!(score_delta, flag_delta)
    self.score += score_delta
    self.flags += flag_delta
    Comment.connection.execute <<~SQL
      UPDATE comments SET
        score = (select coalesce(sum(vote), 0) from votes where comment_id = comments.id),
        flags = (select count(*) from votes where comment_id = comments.id and vote = -1),
        confidence = #{self.calculated_confidence}
      WHERE id = #{self.id.to_i}
    SQL
    self.story.recalculate_hotness!
  end

  def gone_text
    if self.is_moderated?
      "Comment removed by moderator " <<
        self.moderation.try(:moderator).try(:username).to_s << ": " <<
        (self.moderation.try(:reason) || "No reason given")
    elsif self.user.is_banned?
      "Comment from banned user removed"
    else
      "Comment removed by author"
    end
  end

  def has_been_edited?
    self.updated_at && (self.updated_at - self.created_at > 1.minute)
  end

  def html_class_for_user
    c = []
    if !self.user.is_active?
      c.push "inactive_user"
    elsif self.user.is_new?
      c.push "new_user"
    elsif self.story && self.story.user_is_author? &&
          self.story.user_id == self.user_id
      c.push "user_is_author"
    end

    c.join("")
  end

  def is_deletable_by_user?(user)
    if user && user.is_moderator?
      return true
    elsif user && user.id == self.user_id
      return self.created_at >= DELETEABLE_DAYS.days.ago
    else
      return false
    end
  end

  def is_disownable_by_user?(user)
    user && user.id == self.user_id && self.created_at && self.created_at < DELETEABLE_DAYS.days.ago
  end

  def is_flaggable?
    if self.created_at && self.score > FLAGGABLE_MIN_SCORE
      Time.current - self.created_at <= FLAGGABLE_DAYS.days
    else
      false
    end
  end

  def is_editable_by_user?(user)
    if user && user.id == self.user_id
      if self.is_moderated?
        return false
      else
        return (Time.current.to_i - (self.updated_at ? self.updated_at.to_i :
          self.created_at.to_i) < (60 * MAX_EDIT_MINS))
      end
    else
      return false
    end
  end

  def is_gone?
    is_deleted? || is_moderated?
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

  def log_hat_use
    return unless self.hat && self.hat.modlog_use

    m = Moderation.new
    m.created_at = self.created_at
    m.comment_id = self.id
    m.moderator_user_id = user.id
    m.action = "used #{self.hat.hat} hat"
    m.save!
  end

  def mark_submitter
    Keystore.increment_value_for("user:#{self.user_id}:comments_posted")
  end

  def mailing_list_message_id
    [
      "comment",
      self.short_id,
      self.is_from_email ? "email" : nil,
      created_at.to_i,
    ].reject(&:!).join(".") << "@" << Rails.application.domain
  end

  def path
    self.story.comments_path + "#c_#{self.short_id}"
  end

  def plaintext_comment
    # TODO: linkify then strip tags and convert entities back
    comment
  end

  def record_initial_upvote
    Vote.vote_thusly_on_story_or_comment_for_user_because(
      1, self.story_id, self.id, self.user_id, nil, false
    )

    self.story.update_comments_count!
  end

  def score_for_user(u)
    if self.show_score_to_user?(u)
      score
    elsif u && u.can_flag?(self)
      "~"
    else
      "&nbsp;".html_safe
    end
  end

  def short_id_url
    Rails.application.root_url + "c/#{self.short_id}"
  end

  def show_score_to_user?(u)
    return true if u && u.is_moderator?

    # hide score on new/near-zero comments to cut down on threads about voting
    # also hide if user has flagged the story/comment to make retaliatory flagging less fun
    (
      (self.created_at && self.created_at < 36.hours.ago) ||
      !SCORE_RANGE_TO_HIDE.include?(self.score)
    ) && (!current_vote || current_vote[:vote] >= 0)
  end

  def to_param
    self.short_id
  end

  def unassign_votes
    self.story.update_comments_count!
  end

  def url
    self.story.comments_url + "#c_#{self.short_id}"
  end

  def vote_summary_for_user(u)
    r_counts = {}
    r_users = {}
    # don't includes(:user) here and assume the caller did this already
    self.votes.each do |v|
      r_counts[v.reason.to_s] ||= 0
      r_counts[v.reason.to_s] += v.vote

      r_users[v.reason.to_s] ||= []
      r_users[v.reason.to_s].push v.user.username
    end

    r_counts.keys.map {|k|
      next if k == ""

      o = "#{r_counts[k]} #{Vote::ALL_COMMENT_REASONS[k]}"
      if u && u.is_moderator? && self.user_id != u.id
        o << " (#{r_users[k].join(', ')})"
      end
      o
    }.compact.join(", ")
  end

  def undelete_for_user(user)
    Comment.record_timestamps = false

    self.is_deleted = false

    if user.is_moderator?
      self.is_moderated = false

      if user.id != self.user_id
        m = Moderation.new
        m.comment_id = self.id
        m.moderator_user_id = user.id
        m.action = "undeleted comment"
        m.save
      end
    end

    self.save(:validate => false)
    Comment.record_timestamps = true

    self.story.update_comments_count!
    self.user.refresh_counts!
  end
end
