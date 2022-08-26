class Domain < ApplicationRecord
  has_many :stories # rubocop:disable Rails/HasManyOrHasOneDependent
  belongs_to :banned_by_user,
             :class_name => "User",
             :inverse_of => false,
             :optional => true
  validates :banned_reason, :length => { :maximum => 200 }

  validates :domain, presence: true

  def ban_by_user_for_reason!(banner, reason)
    banning_switcher(:on, banner, reason)
  end

  def unban_by_user!(banner)
    banning_switcher(:off, banner)
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

private

  def banning_switcher(state, banner, reason = nil)
    self.banned_at = state == :on ? Time.current : nil
    self.banned_by_user_id = state == :on ? banner.id : nil
    self.banned_reason = state == :on ? reason : nil
    self.save!

    m = Moderation.new
    m.moderator_user_id = banner.id
    m.domain = self
    m.action = state == :on ? 'Banned' : 'Unbanned'
    m.reason = reason
    m.save!
  end
end
