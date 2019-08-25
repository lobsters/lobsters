class InvitationRequest < ApplicationRecord
  validates :name, :presence => true
  validates :email, :format => { :with => /\A[^@ ]+@[^@ ]+\.[^@ ]+\Z/ }, :presence => true
  validates :memo, :format => { :with => /https?:\/\// }

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
