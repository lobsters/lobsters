class InvitationRequest < ApplicationRecord
  validates :name,
            :presence => true,
            :length => { maximum: 255 }
  validates :email,
            :format => { :with => /\A[^@ ]+@[^@ ]+\.[^@ ]+\Z/ },
            :presence => true,
            :length => { maximum: 255 }
  validates :memo,
            :format => { :with => /https?:\/\// },
            :length => { maximum: 255 }
  validates :code, :ip_address, :length => { maximum: 255 }

  before_validation :create_code
  after_create :send_email

  def self.verified_count
    InvitationRequest.where(:is_verified => true).count
  end

  def create_code
    10.times do
      self.code = Utils.random_str(15)
      return unless InvitationRequest.exists?(:code => self.code)
    end
    raise "too many hash collisions"
  end

  def markeddown_memo
    Markdowner.to_html(self.memo)
  end

  def send_email
    InvitationRequestMailer.invitation_request(self).deliver_now
  end
end
