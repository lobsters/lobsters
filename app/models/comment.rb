class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :story,
    :inverse_of => :comments
  has_many :votes,
    :dependent => :delete_all
  belongs_to :parent_comment,
    :class_name => "Comment"
  has_one :moderation,
    :class_name => "Moderation"

  attr_accessor :current_vote, :previewing, :indent_level, :highlighted

  before_validation :on => :create do
    self.assign_short_id_and_upvote
    self.assign_initial_confidence
    self.assign_thread_id
  end
  after_create :record_initial_upvote, :mark_submitter,
    :deliver_reply_notifications, :deliver_mention_notifications,
    :log_to_countinual
  after_destroy :unassign_votes

  DOWNVOTABLE_DAYS = 7

  # after this many minutes old, a comment cannot be edited
  MAX_EDIT_MINS = (60 * 4)

  validate do
    self.comment.to_s.strip == "" &&
      errors.add(:comment, "cannot be blank.")

    self.user_id.blank? &&
      errors.add(:user_id, "cannot be blank.")

    self.story_id.blank? &&
      errors.add(:story_id, "cannot be blank.")

    (m = self.comment.to_s.strip.match(/\A(t)his([\.!])?$\z/i)) &&
      errors.add(:base, (m[1] == "T" ? "N" : "n") + "ope" + m[2].to_s)
  end

  def self.arrange_for_user(user)
    parents = self.order("confidence DESC").group_by(&:parent_comment_id)

    # top-down list of comments, regardless of indent level
    ordered = []

    ancestors = [nil] # nil sentinel so indent_level starts at 1 without add op.
    subtree = parents[nil]

    while subtree
      if (node = subtree.shift)
        children = parents[node.id]

        # for deleted comments, if they have no children, they can be removed
        # from the tree.  otherwise they have to stay and a "[deleted]" stub
        # will be shown
        if !node.is_gone?
          # not deleted or moderated
        elsif children
          # we have child comments
        elsif user && (user.is_moderator? || node.user_id == user.id)
          # admins and authors should be able to see their deleted comments
        else
          # drop this one
          next
        end

        node.indent_level = ancestors.length
        ordered << node

        # no children to recurse
        next unless children

        # for moderated threads, remove the entire sub-tree at the moderation
        # point
        next if node.is_moderated?

        # drill down a level
        ancestors << subtree
        subtree = children
      else
        # climb back out
        subtree = ancestors.pop
      end
    end

    ordered
  end

  def self.regenerate_markdown
    Comment.record_timestamps = false

    Comment.all.each do |c|
      c.markeddown_comment = c.generated_markeddown_comment
      c.save(:validate => false)
    end

    Comment.record_timestamps = true

    nil
  end

  def as_json(options = {})
    h = super(:only => [
      :short_id,
      :created_at,
      :updated_at,
      :is_deleted,
      :is_moderated,
    ])
    h[:score] = score

    if self.is_gone?
      h[:comment] = "<em>#{self.gone_text}</em>"
    else
      h[:comment] = markeddown_comment
    end

    h[:url] = url
    h[:indent_level] = indent_level
    h[:commenting_user] = user
    h
  end

  def assign_initial_confidence
    self.confidence = self.calculated_confidence
  end

  def assign_short_id_and_upvote
    self.short_id = ShortId.new(self.class).generate
    self.upvotes = 1
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
    n = (upvotes + downvotes).to_f
    if n == 0.0
      return 0
    end

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

  def delete_for_user(user)
    Comment.record_timestamps = false

    self.is_deleted = true

    if user.is_moderator? && user.id != self.user_id
      self.is_moderated = true

      m = Moderation.new
      m.comment_id = self.id
      m.moderator_user_id = user.id
      m.action = "deleted comment"
      m.save
    end

    self.save(:validate => false)
    Comment.record_timestamps = true

    self.story.update_comments_count!
  end

  def deliver_mention_notifications
    self.plaintext_comment.scan(/\B\@([\w\-]+)/).flatten.uniq.each do |mention|
      if u = User.where(:username => mention).first
        if u.id == self.user.id
          next
        end

        if u.email_mentions?
          begin
            EmailReply.mention(self, u).deliver
          rescue => e
            Rails.logger.error "error e-mailing #{u.email}: #{e}"
          end
        end

        if u.pushover_mentions?
          u.pushover!({
            :title => "#{Rails.application.name} mention by " <<
              "#{self.user.username} on #{self.story.title}",
            :message => self.plaintext_comment,
            :url => self.url,
            :url_title => "Reply to #{self.user.username}",
          })
        end
      end
    end
  end

  def deliver_reply_notifications
    if self.parent_comment_id && (u = self.parent_comment.try(:user)) &&
    u.id != self.user.id
      if u.email_replies?
        begin
          EmailReply.reply(self, u).deliver
        rescue => e
          Rails.logger.error "error e-mailing #{u.email}: #{e}"
        end
      end

      if u.pushover_replies?
        u.pushover!({
          :title => "#{Rails.application.name} reply from " <<
            "#{self.user.username} on #{self.story.title}",
          :message => self.plaintext_comment,
          :url => self.url,
          :url_title => "Reply to #{self.user.username}",
        })
      end
    end
  end

  def generated_markeddown_comment
    Markdowner.to_html(self.comment)
  end

  def give_upvote_or_downvote_and_recalculate_confidence!(upvote, downvote)
    self.upvotes += upvote.to_i
    self.downvotes += downvote.to_i

    Comment.connection.execute("UPDATE #{Comment.table_name} SET " <<
      "upvotes = COALESCE(upvotes, 0) + #{upvote.to_i}, " <<
      "downvotes = COALESCE(downvotes, 0) + #{downvote.to_i}, " <<
      "confidence = '#{self.calculated_confidence}' WHERE id = " <<
      "#{self.id.to_i}")
  end

  def gone_text
    if self.is_moderated?
      "Thread removed by moderator " <<
        self.moderation.try(:moderator).try(:username).to_s << ": " <<
        (self.moderation.try(:reason) || "No reason given")
    else
      "Comment removed by author"
    end
  end

  def has_been_edited?
    self.updated_at && (self.updated_at - self.created_at > 1.minute)
  end

  def is_deletable_by_user?(user)
    if user && user.is_moderator?
      return true
    elsif user && user.id == self.user_id
      return true
    else
      return false
    end
  end

  def is_downvotable?
    if self.created_at
      Time.now - self.created_at <= DOWNVOTABLE_DAYS.days
    else
      false
    end
  end

  def is_editable_by_user?(user)
    if user && user.id == self.user_id
      if self.is_moderated?
        return false
      else
        return (Time.now.to_i - (self.updated_at ? self.updated_at.to_i :
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

  def log_to_countinual
    Countinual.count!("#{Rails.application.shortname}.comments.submitted", "+1")
  end

  def mark_submitter
    Keystore.increment_value_for("user:#{self.user_id}:comments_posted")
  end

  def mailing_list_message_id
    "comment.#{short_id}.#{created_at.to_i}@#{Rails.application.domain}"
  end

  def plaintext_comment
    # TODO: linkify then strip tags and convert entities back
    comment
  end

  def record_initial_upvote
    Vote.vote_thusly_on_story_or_comment_for_user_because(1, self.story_id,
      self.id, self.user_id, nil, false)

    self.story.update_comments_count!
  end

  def score
    self.upvotes - self.downvotes
  end

  def short_id_url
    self.story.short_id_url + "/_/comments/#{self.short_id}"
  end

  def to_param
    self.short_id
  end

  def unassign_votes
    self.story.update_comments_count!
  end

  def url
    self.story.comments_url + "/comments/#{self.short_id}"
  end

  def vote_summary
    r_counts = {}
    Vote.where(:comment_id => self.id).each do |v|
      r_counts[v.reason.to_s] ||= 0
      r_counts[v.reason.to_s] += v.vote
    end

    r_counts.keys.sort.map{|k|
      k == "" ? "+#{r_counts[k]}" : "#{r_counts[k]} #{Vote::COMMENT_REASONS[k]}"
    }.join(", ")
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
  end
end
