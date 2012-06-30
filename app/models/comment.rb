class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :story
  has_many :votes,
    :dependent => :delete_all
  
  attr_accessible :comment

  attr_accessor :parent_comment_short_id, :current_vote, :previewing,
    :indent_level

  before_create :assign_short_id_and_upvote
  after_create :assign_votes
  after_destroy :unassign_votes

  MAX_EDIT_MINS = 45

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

  def assign_short_id_and_upvote
    (1...10).each do |tries|
      if tries == 10
        raise "too many hash collisions"
      end

      if !Comment.find_by_short_id(self.short_id = Utils.random_str(6))
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

  # http://evanmiller.org/how-not-to-sort-by-average-rating.html
  # https://github.com/reddit/reddit/blob/master/r2/r2/lib/db/_sorts.pyx
  def confidence
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

  def unassign_votes
    self.story.update_comment_count!
  end

  def score
    self.upvotes - self.downvotes
  end

  def linkified_comment
    Markdowner.markdown(self.comment)
  end

  def upvote!(amount = 1)
    Story.update_counters self.id, :upvotes => amount
  end

  def flag!
    Story.update_counters self.id, :flaggings => 1
  end

  def self.ordered_for_story_or_thread_for_user(story_id, thread_id, user_id)
    parents = {}

    if thread_id
      cs = [ "thread_id = ?", thread_id ]
    else
      cs = [ "story_id = ?", story_id ]
    end

    Comment.find(:all, :conditions => cs).sort_by{|c| c.confidence }.each do |c|
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

    ordered
  end
  
  def is_editable_by_user?(user)
    if !user || user.id != self.user_id
      return false
    end

    (Time.now.to_i - self.created_at.to_i < (60 * MAX_EDIT_MINS))
  end
end
