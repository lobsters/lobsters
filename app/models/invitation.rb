class Invitation < ApplicationRecord
  belongs_to :user
  belongs_to :new_user, class_name: 'User', inverse_of: nil, optional: true

  scope :used, -> { where.not(:used_at => nil) }
  scope :unused, -> { where(:used_at => nil) }

  validate do
    unless email.to_s.match(/\A[^@ ]+@[^ @]+\.[^ @]+\z/)
      errors.add(:email, "is not valid")
    end
  end

  validates :code, :email, :memo, length: { maximum: 255 }

  before_validation :create_code, :on => :create

  def create_code
    10.times do
      self.code = Utils.random_str(15)
      return unless Invitation.exists?(:code => self.code)
    end
    raise "too many hash collisions"
  end

  def send_email
    InvitationMailer.invitation(self).deliver_now
  end
end
