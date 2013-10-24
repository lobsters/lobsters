class InvitationRequest < ActiveRecord::Base
  attr_accessible nil

  validates :name, :presence => true
  validates :email, :format => { :with => /\A[^@ ]+@[^@ ]+\.[^@ ]+\Z/ }

  before_validation :create_code
  after_create :send_email

  def self.verified_count
    InvitationRequest.where(:is_verified => true).count
  end

  def create_code
    (1...10).each do |tries|
      if tries == 10
        raise "too many hash collisions"
      end

      if !InvitationRequest.find_by_code(self.code = Utils.random_str(15))
        break
      end
    end
  end

  def markeddown_memo
    Markdowner.to_html(self.memo)
  end
  
  def send_email
    InvitationRequestMailer.invitation_request(self).deliver
  end
end
