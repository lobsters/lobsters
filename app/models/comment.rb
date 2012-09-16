class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :story
  has_many :votes,
    :dependent => :delete_all
  belongs_to :parent_comment,
    :class_name => "Comment"
  
  attr_accessible :comment, :moderation_reason

  attr_accessor :parent_comment_short_id, :current_vote, :previewing,
    :indent_level, :highlighted

  before_create :assign_short_id_and_upvote, :assign_initial_confidence
  after_create :assign_votes, :mark_submitter, :deliver_reply_notifications,
    :deliver_mention_notifications
  after_destroy :unassign_votes

  MAX_EDIT_MINS = 45

  define_index do
    indexes comment
    indexes user.username, :as => :author
    
    has "(upvotes - downvotes)", :as => :score, :type => :integer,
      :sortable => true
    
    has is_deleted
    has created_at

    where "is_deleted = 0"
  end

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

  def self.regenerate_markdown
    Comment.record_timestamps = false

    Comment.all.each do |c|
      c.markeddown_comment = c.generated_markeddown_comment
      c.save(:validate => false)
    end

    Comment.record_timestamps = true

    nil
  end

  def assign_short_id_and_upvote
    10.times do |try|
      if try == 10
        raise "too many hash collisions"
      end

      self.short_id = Utils.random_str(6).downcase

      if !Comment.find_by_short_id(self.short_id)
        break
      end
    end

    self.upvotes = 1
  end

  def assign_votes
    Vote.vote_thusly_on_story_or_comment_for_user_because(1, self.story_id,
      self.id, self.user.id, nil, false)

    self.story.update_comment_count!
  end

  def downvote_summary
    reasons = {}
    Vote.where(:comment_id => self.id).each do |v|
      reasons[v.reason] ||= 0
      reasons[v.reason] += 1
    end

    reasons.map{|r,v| "#{Vote::COMMENT_REASONS[r]} (#{v})" }.join(", ")
  end
  
  def is_gone?
    is_deleted?
  end

  def mark_submitter
    Keystore.increment_value_for("user:#{self.user_id}:comments_posted")
  end

  def deliver_mention_notifications
    self.plaintext_comment.scan(/\B\@([\w\-]+)/).flatten.uniq.each do |mention|
      if u = User.find_by_username(mention)
        begin
          if u.email_mentions?
            EmailReply.mention(self, u).deliver
          end

          if u.pushover_mentions? && u.pushover_user_key.present?
            Pushover.push(u.pushover_user_key, u.pushover_device, {
              :title => "Lobsters mention by #{self.user.username} on " <<
                self.story.title,
              :message => self.plaintext_comment,
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

  def deliver_reply_notifications
    if self.parent_comment_id && u = self.parent_comment.try(:user)
      begin
        if u.email_replies?
          EmailReply.reply(self, u).deliver
        end

        if u.pushover_replies? && u.pushover_user_key.present?
          Pushover.push(u.pushover_user_key, u.pushover_device, {
            :title => "Lobsters reply from #{self.user.username} on " <<
              "#{self.story.title}",
            :message => self.plaintext_comment,
            :url => self.url,
            :url_title => "Reply to #{self.user.username}",
          })
        end
      rescue => e
        Rails.logger.error "failed to deliver reply notification to " <<
          "#{u.username}: #{e.message}"
      end
    end
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

    self.story.update_comment_count!
  end

  def undelete_for_user(user)
    Comment.record_timestamps = false

    self.is_deleted = false

    if user.is_moderator? && user.id != self.user_id
      self.is_moderated = true

      m = Moderation.new
      m.comment_id = self.id
      m.moderator_user_id = user.id
      m.action = "undeleted comment"
      m.save
    end

    self.save(:validate => false)
    Comment.record_timestamps = true
    
    self.story.update_comment_count!
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

  def assign_initial_confidence
    self.confidence = self.calculated_confidence
  end

  def unassign_votes
    self.story.update_comment_count!
  end

  def score
    self.upvotes - self.downvotes
  end

  def generated_markeddown_comment
    Markdowner.to_html(self.comment)
  end
    
  def comment=(com)
    self[:comment] = com.to_s.rstrip
    self.markeddown_comment = self.generated_markeddown_comment
  end

  def plaintext_comment
    # TODO: linkify then strip tags and convert entities back
    comment
  end

  def flag!
    Story.update_counters self.id, :flaggings => 1
  end

  def has_been_edited?
    self.updated_at && (self.updated_at - self.created_at > 1.minute)
  end

  def self.ordered_for_story_or_thread_for_user(story_id, thread_id, user)
    parents = {}

    if thread_id
      cs = [ "thread_id = ?", thread_id ]
    else
      cs = [ "story_id = ?", story_id ]
    end

    Comment.find(:all, :conditions => cs, :order => "confidence DESC",
    :include => :user).each do |c|
      (parents[c.parent_comment_id.to_i] ||= []).push c
    end

    # top-down list of comments, regardless of indent level
    ordered = []

    recursor = lambda{|comment,level|
      if comment
        comment.indent_level = level
        ordered.push comment
      end

      # for each comment that is a child of this one, recurse with it
      (parents[comment ? comment.id : 0] || []).each do |child|
        recursor.call(child, level + 1)
      end
    }
    recursor.call(nil, 0)

    # for deleted comments, if they have no children, they can be removed from
    # the tree.  otherwise they have to stay and a "[deleted]" stub will be
    # shown
    new_ordered = []
    ordered.each_with_index do |c,x|
      if c.is_gone?
        if ordered[x + 1] && (ordered[x + 1].indent_level > c.indent_level)
          # we have child comments, so we must stay
        elsif user && (user.is_moderator? || c.user_id == user.id)
          # admins and authors should be able to see their deleted comments
        else
          # drop this one
          next
        end
      end

      new_ordered.push c
    end

    new_ordered
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
  
  def is_deletable_by_user?(user)
    if user && user.is_moderator?
      return true
    elsif user && user.id == self.user_id
      return true
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

  def short_id_url
    self.story.short_id_url + "/_/comments/#{self.short_id}"
  end

  def url
    self.story.comments_url + "/comments/#{self.short_id}"
  end
end
