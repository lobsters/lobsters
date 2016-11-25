class BlockedUser < ActiveRecord::Base
  belongs_to :user

  validates :blocked_user_id, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true

  validate :cant_block_self

  private

  def cant_block_self
    errors.add(:base, 'Cannot block self') if blocked_user_id == user_id
  end
end
