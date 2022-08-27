class Domain < ApplicationRecord
  has_many :stories # rubocop:disable Rails/HasManyOrHasOneDependent
  belongs_to :banned_by_user,
             :class_name => "User",
             :inverse_of => false,
             :optional => true
  validates :banned_reason, :length => { :maximum => 200 }

  validates :domain, presence: true

  def ban_by_user_for_reason!(banner, reason)
    self.banned_at = Time.current
    self.banned_by_user_id = banner.id
    self.banned_reason = reason
    self.save!

    m = Moderation.new
    m.moderator_user_id = banner.id
    m.domain = self
    m.action = 'Banned'
    m.reason = reason
    m.save!
  end

  def unban_by_user_for_reason!(banner, reason)
    self.banned_at = nil
    self.banned_by_user_id = nil
    self.banned_reason = nil
    self.save!

    m = Moderation.new
    m.moderator_user_id = banner.id
    m.domain = self
    m.action = 'Unbanned'
    m.reason = reason
    m.save!
  end

  def banned?
    banned_at?
  end

  def n_submitters
    self.stories.count('distinct user_id')
  end

  def to_param
    domain
  end
end
