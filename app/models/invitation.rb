class Invitation < ActiveRecord::Base
  belongs_to :user

  attr_accessible nil

  validate do
    unless email.to_s.match(/\A[^@ ]+@[^ @]+\.[^ @]+\z/)
      errors.add(:email, "is not valid")
    end
  end

  before_validation :create_code,
    :on => :create

  def create_code
    (1...10).each do |tries|
      if tries == 10
        raise "too many hash collisions"
      end

      if !Invitation.find_by_code(self.code = Utils.random_str(15))
        break
      end
    end
  end

  def send_email
    InvitationMailer.invitation(self).deliver
  end
end
