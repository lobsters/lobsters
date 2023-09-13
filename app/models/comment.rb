class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :story,
    inverse_of: :comments
  has_many :votes,
    dependent: :delete_all
  belongs_to :parent_comment,
    class_name: "Comment",
    inverse_of: false,
    optional: true
  has_one :moderation,
    class_name: "Moderation",
    inverse_of: :comment,
    dependent: :destroy
  belongs_to :hat,
    optional: true
  has_many :taggings, through: :story

  attr_accessor :current_vote, :previewing
  attribute :depth, :integer
  attribute :reply_count, :integer

  before_validation on: :create do
    assign_short_id_and_score
    assign_initial_confidence
    assign_thread_id
  end
  after_create :record_initial_upvote, :mark_submitter, :deliver_reply_notifications,
    :deliver_mention_notifications, :log_hat_use
  after_create do
    # fire this once after record_initial_upvote
    update_score_and_recalculate! 0, 0
  end
  after_destroy :unassign_votes

  scope :deleted, -> { where(is_deleted: true) }
  scope :not_deleted, -> { where(is_deleted: false) }
  scope :not_moderated, -> { where(is_moderated: false) }
  scope :active, -> { not_deleted.not_moderated }
  scope :accessible_to_user, ->(user) { (user && user.is_moderator?) ? all : active }
  scope :for_presentation, -> {
    includes(:user, :hat, moderation: :moderator, story: :user, votes: :user)
  }
  scope :not_on_story_hidden_by, ->(user) {
    user ? where.not(
      HiddenStory.select("TRUE")
      .where(Arel.sql("hidden_stories.story_id = stories.id"))
      .by(user).arel.exists
    ) : where("true")
  }
  # workaround: if this select is in #parents, calling .count produces invalid SQL
  scope :with_thread_attributes, -> {
    select("comments.*, comments_recursive.depth as depth, comments_recursive.reply_count")
  }

  FLAGGABLE_DAYS = 7
  DELETEABLE_DAYS = FLAGGABLE_DAYS * 2

  # the lowest a score can go
  FLAGGABLE_MIN_SCORE = -10

  # the score at which a comment should be collapsed
  COLLAPSE_SCORE = -5

  # after this many minutes old, a comment cannot be edited
  MAX_EDIT_MINS = (60 * 6)

  # story_threads builds a confidence_order_path in SQL this many characters long:
  # the longest reply chain in prod data is 31 comments (so, depth 30) * 3b confidence_order
  COP_LENGTH = 31 * 3
  # Stop accepting replies this deep. Recursive CTE requires a fixed max (COP_LENGTH),
  # but in practice all deep reply chains have gone off-topic and/or tuned into flamewars.
  MAX_DEPTH = 18

  SCORE_RANGE_TO_HIDE = (-2..4)

  validates :short_id, length: {maximum: 10}
  validates :user_id, presence: true
  validates :story_id, presence: true
  validates :markeddown_comment, length: {maximum: 16_777_215}
  validates :comment, presence: {with: true, message: "cannot be empty."}

  validate do
    parent_comment&.is_gone? &&
      errors.add(:base, "Comment was deleted by the author or a mod while you were writing.")

    parent_comment && !parent_comment.depth_permits_reply? &&
      ModNote.tattle_on_max_depth_limit(user, parent_comment) &&
      errors.add(:base, "You have replied too greedily and too deep.")

    (m = comment.to_s.strip.match(/\A(t)his([\.!])?$\z/i)) &&
      errors.add(:base, ((m[1] == "T") ? "N" : "n") + "ope" + m[2].to_s)

    comment.to_s.strip.match(/\Atl;?dr.?$\z/i) &&
      errors.add(:base, "Wow!  A blue car!")

    comment.to_s.strip.match(/\A([[[:upper:]][[:punct:]]] )+[[[:upper:]][[:punct:]]]?$\z/) &&
      errors.add(:base, "D O N ' T")

    comment.to_s.strip.match(/\A(me too|nice)([\.!])?\z/i) &&
      errors.add(:base, "Please just upvote the parent post instead.")

    hat.present? && user.wearable_hats.exclude?(hat) &&
      errors.add(:hat, "not wearable by user")

    # .try so tests don't need to persist a story and user
    story.try(:accepting_comments?) ||
      errors.add(:base, "Story is no longer accepting comments.")
  end

  def self.regenerate_markdown
    Comment.record_timestamps = false

    Comment.all.find_each do |c|
      c.markeddown_comment = c.generated_markeddown_comment
      c.save(validate: false)
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
      {parent_comment: parent_comment&.short_id},
      {comment: (is_gone? ? "<em>#{gone_text}</em>" : :markeddown_comment)},
      {comment_plain: (is_gone? ? gone_text : :comment)},
      :url,
      :depth,
      {commenting_user: :user}
    ]

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

  def assign_initial_confidence
    self.confidence = calculated_confidence
    # 3 byte placeholder, immediately replaced by after_create callback calling
    # update_score_and_recalculate! to fill in the autogenerated 'id' value
    self.confidence_order = [0, 0, 0].pack("CCC")
  end

  def assign_short_id_and_score
    self.short_id = ShortId.new(self.class).generate
    self.score ||= 1 # tests are allowed to fake out the score
  end

  def assign_thread_id
    self.thread_id = if parent_comment.present?
      parent_comment.thread_id
    else
      Keystore.incremented_value_for("thread_id")
    end
  end

  # http://evanmiller.org/how-not-to-sort-by-average-rating.html
  # https://github.com/reddit/reddit/blob/master/r2/r2/lib/db/_sorts.pyx
  def calculated_confidence
    return 0 if self.score == 0 && flags == 0
    n = (self.score + flags * 2).to_f

    upvotes = self.score + flags
    z = 1.281551565545 # 80% confidence
    p = upvotes.to_f / n

    left = p + (1 / ((2.0 * n) * z * z))
    right = z * Math.sqrt((p * ((1.0 - p) / n)) + (z * (z / (4.0 * n * n))))
    under = 1.0 + ((1.0 / n) * z * z)

    (left - right) / under
  end

  # rate-limit users in heated reply chains, called by controller so that authors can preview
  # without seeing the message
  def breaks_speed_limit?
    return false unless parent_comment_id
    return false if user.is_moderator?

    parent_comment_ids = parent_comment.parents.pluck(:id).append(parent_comment.id)
    flag_count = Vote.comments_flags(parent_comment_ids).count
    commenter_flag_count = Vote.comments_flags(parent_comment_ids, user).count # double-count author
    delay = (2 + flag_count + commenter_flag_count).minutes

    recent = Comment.where("created_at >= ?", delay.ago)
      .find_by(user: user, thread_id: parent_comment.thread_id)

    return false unless recent.present?

    wait = ActionController::Base.helpers
      .distance_of_time_in_words(Time.now, (recent.created_at + delay))
    Rails.logger.info "breaks_speed_limit: #{user.username} replying to https://lobste.rs/c/#{parent_comment.short_id} parent_comment_ids (#{parent_comment_ids.join(" ")}) flags #{flag_count} commenter_flag_count #{commenter_flag_count} delay #{delay} delay.ago #{delay.ago} recent #{recent.id}"
    errors.add(
      :comment,
      "Thread speed limit reached, next comment allowed in #{wait}. " +
      (flag_count.zero? ? "" : "Is this thread getting heated? ") +
      (commenter_flag_count.zero? ? "" : "You flagged here, you can leave it for mods.")
    )
  end

  def comment=(com)
    self[:comment] = com.to_s.rstrip
    self.markeddown_comment = generated_markeddown_comment
  end

  # current_vote is the vote loaded for the currently-viewing user
  def current_flagged?
    current_vote.try(:[], :vote) == -1
  end

  def current_upvoted?
    current_vote.try(:[], :vote) == 1
  end

  def delete_for_user(user, reason = nil)
    Comment.record_timestamps = false

    self.is_deleted = true

    if user.is_moderator? && user.id != user_id
      self.is_moderated = true

      m = Moderation.new
      m.comment_id = id
      m.moderator_user_id = user.id
      m.action = "deleted comment"

      if reason.present?
        m.reason = reason
      end

      m.save

      User.update_counters user_id, karma: (votes.count * -2)
    end

    save(validate: false)
    Comment.record_timestamps = true

    story.update_comments_count!
    self.user.refresh_counts!
  end

  def deliver_mention_notifications
    plaintext_comment.scan(/\B@([\w\-]+)/).flatten.uniq.each do |mention|
      if (u = User.active.find_by(username: mention))
        if u.id == user.id
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
            title: "#{Rails.application.name} mention by " \
              "#{user.username} on #{story.title}",
            message: plaintext_comment,
            url: url,
            url_title: "Reply to #{user.username}"
          )
        end
      end
    end
  end

  def users_following_thread
    users_following_thread = Set.new
    if user.id != story.user.id && story.user_is_following
      users_following_thread << story.user
    end

    if parent_comment_id &&
        (u = parent_comment.try(:user)) &&
        u.id != user.id &&
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
          title: "#{Rails.application.name} reply from " \
            "#{user.username} on #{story.title}",
          message: plaintext_comment,
          url: url,
          url_title: "Reply to #{user.username}"
        )
      end
    end
  end

  def depth_permits_reply?
    # Top-level replies (eg parent_comment_id == null) have depth 0, then each reply is +1.
    # Alternate definition: depth is the number of ancestor comments.

    return false if new_record? # can't reply to unsaved comments

    # Most commonly, depth is set by merged_comments. But we need to count parents when executing as
    # a validation on reply.
    self.depth ||= parents.count

    depth < MAX_DEPTH
  end

  def generated_markeddown_comment
    Markdowner.to_html(comment)
  end

  # TODO: race condition: if two votes arrive at the same time, the second one
  # won't take the first's score change into effect for calculated_confidence
  def update_score_and_recalculate!(score_delta, flag_delta)
    self.score += score_delta
    self.flags += flag_delta
    # confidence_order allows sorting sibling comments by confidence in queries like story_threads.
    # confidence_order must sort in ascending order so that it's in the right order when
    # concatenated into confidence_order_path, which the database sorts lexiographically. It is 3
    # bytes wide. The first two bytes map confidence to a big-endian unsigned integer, inverted so
    # that high-confidence have low values. confidence is based on the number of upvotes and flags,
    # so some values (like the one for 1 vote, 0 flags) are very common, causing sibling comments to
    # tie. If we don't specify a tiebreaker, the database will return results in an arbitrary order,
    # which means sibling comments will swap positions on page reloads (infrequently and
    # intermittently, real fun to debug). So the third byte is the low byte of the comment id. Being
    # assigned sequentially, mostly the tiebreaker sorts earlier comments sooner. We average ~200
    # comments per weekday so seeing rollover between sibling comments is rare. Importantly, even
    # when it is 'wrong', it gives a stable sort.
    Comment.connection.execute <<~SQL
      UPDATE comments SET
        score = (select coalesce(sum(vote), 0) from votes where comment_id = comments.id),
        flags = (select count(*) from votes where comment_id = comments.id and vote = -1),
        confidence = #{calculated_confidence},
        confidence_order = concat(lpad(char(65536 - floor(((confidence - -0.2) * 65535) / 1.2) using binary), 2, '0'), char(id & 0xff using binary))
      WHERE id = #{id.to_i}
    SQL
    story.recalculate_hotness!
  end

  def gone_text
    if is_moderated?
      "Comment removed by moderator " <<
        moderation.try(:moderator).try(:username).to_s << ": " <<
        (moderation.try(:reason) || "No reason given")
    elsif user.is_banned?
      "Comment from banned user removed"
    else
      "Comment removed by author"
    end
  end

  def has_been_edited?
    updated_at && (updated_at - created_at > 1.minute)
  end

  def is_deletable_by_user?(user)
    if user&.is_moderator?
      true
    elsif user && user.id == user_id
      created_at >= DELETEABLE_DAYS.days.ago
    else
      false
    end
  end

  def is_disownable_by_user?(user)
    user && user.id == user_id && created_at && created_at < DELETEABLE_DAYS.days.ago
  end

  def is_flaggable?
    if created_at && self.score > FLAGGABLE_MIN_SCORE
      Time.current - created_at <= FLAGGABLE_DAYS.days
    else
      false
    end
  end

  def is_editable_by_user?(user)
    if user && user.id == user_id
      if is_moderated?
        false
      else
        (Time.current.to_i - (updated_at ? updated_at.to_i :
          created_at.to_i) < (60 * MAX_EDIT_MINS))
      end
    else
      false
    end
  end

  def is_gone?
    is_deleted? || is_moderated?
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

  def log_hat_use
    return unless hat&.modlog_use

    m = Moderation.new
    m.created_at = created_at
    m.comment_id = id
    m.moderator_user_id = user.id
    m.action = "used #{hat.hat} hat"
    m.save!
  end

  def mark_submitter
    Keystore.increment_value_for("user:#{user_id}:comments_posted")
  end

  def mailing_list_message_id
    [
      "comment",
      short_id,
      is_from_email ? "email" : nil,
      created_at.to_i
    ].reject(&:!).join(".") << "@" << Rails.application.domain
  end

  # all direct ancestors of this comment, oldest first
  def parents
    return Comment.none if parent_comment_id.nil?

    # starts from parent_comment_id so it works on new records
    @parents ||= Comment
      .joins(<<~SQL
        inner join (
          with recursive parents as (
            select
              id target_id,
              id,
              parent_comment_id,
              0 as depth,
              (select count(*) from comments where parent_comment_id = id) as reply_count
            from comments where id = #{parent_comment_id}
            union all
            select
              parents.target_id,
              c.id,
              c.parent_comment_id,
              depth - 1,
              (select count(*) from comments where parent_comment_id = c.id)
            from comments c join parents on parents.parent_comment_id = c.id
          ) select id, depth, reply_count from parents
        ) as comments_recursive on comments.id = comments_recursive.id
      SQL
            )
      .order("id asc")
  end

  def path
    story.comments_path + "#c_#{short_id}"
  end

  def plaintext_comment
    # TODO: linkify then strip tags and convert entities back
    comment
  end

  def record_initial_upvote
    Vote.vote_thusly_on_story_or_comment_for_user_because(
      1, story_id, id, user_id, nil, false
    )

    story.update_comments_count!
  end

  def score_for_user(u)
    if show_score_to_user?(u)
      score
    elsif u&.can_flag?(self)
      "~"
    else
      "&nbsp;".html_safe
    end
  end

  def short_id_url
    Rails.application.root_url + "c/#{short_id}"
  end

  def show_score_to_user?(u)
    return true if u&.is_moderator?

    # hide score on new/near-zero comments to cut down on threads about voting
    # also hide if user has flagged the story/comment to make retaliatory flagging less fun
    (
      (created_at && created_at < 36.hours.ago) ||
      !SCORE_RANGE_TO_HIDE.include?(self.score)
    ) && !current_flagged?
  end

  def to_param
    short_id
  end

  def unassign_votes
    story.update_comments_count!
  end

  def url
    story.comments_url + "#c_#{short_id}"
  end

  def vote_summary_for_user(u)
    r_counts = {}
    r_users = {}
    # don't includes(:user) here and assume the caller did this already
    votes.each do |v|
      r_counts[v.reason.to_s] ||= 0
      r_counts[v.reason.to_s] += v.vote

      r_users[v.reason.to_s] ||= []
      r_users[v.reason.to_s].push v.user.username
    end

    r_counts.keys.map { |k|
      next if k == ""

      o = "#{r_counts[k]} #{Vote::ALL_COMMENT_REASONS[k]}"
      if u && u.is_moderator? && user_id != u.id
        o << " (#{r_users[k].join(", ")})"
      end
      o
    }.compact.join(", ")
  end

  def undelete_for_user(user)
    Comment.record_timestamps = false

    self.is_deleted = false

    if user.is_moderator?
      self.is_moderated = false

      if user.id != user_id
        m = Moderation.new
        m.comment_id = id
        m.moderator_user_id = user.id
        m.action = "undeleted comment"
        m.save
      end
    end

    save(validate: false)
    Comment.record_timestamps = true

    story.update_comments_count!
    self.user.refresh_counts!
  end

  def self.recent_threads(user)
    return Comment.none unless user.try(:id)

    thread_ids = Comment
      .where(user: user)
      .group(:thread_id)
      .order("id desc")
      .limit(20)
      .pluck(:thread_id)
    return Comment.none if thread_ids.empty?

    Comment
      .joins(<<~SQL
        inner join (
          with recursive discussion as (
          select
            c.id,
            0 as depth,
            (select count(*) from comments where parent_comment_id = c.id) as reply_count,
            cast(confidence_order as char(#{Comment::COP_LENGTH}) character set binary) as confidence_order_path
            from comments c
            where
              thread_id in (#{thread_ids.join(", ")}) and
              parent_comment_id is null
          union all
          select
            c.id,
            discussion.depth + 1,
            (select count(*) from comments where parent_comment_id = c.id),
            cast(concat(
              left(discussion.confidence_order_path, 3 * (depth + 1)),
              c.confidence_order
            ) as char(#{Comment::COP_LENGTH}) character set binary)
          from comments c join discussion on c.parent_comment_id = discussion.id
          )
          select * from discussion as comments
        ) as comments_recursive on comments.id = comments_recursive.id
      SQL
            )
      .order("comments.thread_id desc, comments_recursive.confidence_order_path")
      .select('
        comments.*,
        comments_recursive.depth as depth,
        comments_recursive.reply_count as reply_count
      ')
  end

  # select in thread order with preloading for _comment.html.erb
  def self.story_threads(story)
    return Comment.none unless story.id # unsaved Stories have no comments

    # If the story_ids predicate is in the outer select the query planner doesn't push it down into
    # the recursive CTE, so that subquery would build the tree for the entire comments table.
    Comment
      .joins(<<~SQL
        inner join (
          with recursive discussion as (
          select
            c.id,
            0 as depth,
            (select count(*) from comments where parent_comment_id = c.id) as reply_count,
            cast(confidence_order as char(#{Comment::COP_LENGTH}) character set binary) as confidence_order_path
            from comments c
            join stories on stories.id = c.story_id
            where
              (stories.id = #{story.id} or stories.merged_story_id = #{story.id}) and
              parent_comment_id is null
          union all
          select
            c.id,
            discussion.depth + 1,
            (select count(*) from comments where parent_comment_id = c.id),
            cast(concat(
              left(discussion.confidence_order_path, 3 * (depth + 1)),
              c.confidence_order
            ) as char(#{Comment::COP_LENGTH}) character set binary)
          from comments c join discussion on c.parent_comment_id = discussion.id
          )
          select * from discussion as comments
        ) as comments_recursive on comments.id = comments_recursive.id
      SQL
            )
      .order("comments_recursive.confidence_order_path")
      .select('
        comments.*,
        comments_recursive.depth as depth,
        comments_recursive.reply_count as reply_count
      ')
  end
end
