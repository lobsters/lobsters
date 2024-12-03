# typed: false

class Invitation < ApplicationRecord
  belongs_to :user
  belongs_to :new_user, class_name: "User", inverse_of: nil, optional: true

  scope :used, -> { where.not(used_at: nil) }
  scope :unused, -> { where(used_at: nil) }

  validate do
    unless /\A[^@ ]+@[^ @]+\.[^ @]+\z/.match?(email.to_s)
      errors.add(:email, "is not valid")
    end
  end

  validates :code, :email, length: {maximum: 255}
  validates :memo, length: {maximum: 375}

  before_validation :create_code, on: :create

  def create_code
    10.times do
      self.code = Utils.random_str(15)
      return unless Invitation.exists?(code: code)
    end
    raise "too many hash collisions"
  end

  def send_email
    InvitationMailer.invitation(self).deliver_now
  end
end
