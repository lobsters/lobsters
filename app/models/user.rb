class User < ActiveRecord::Base
	has_many :stories,
    :include => :user
  has_secure_password

  validates_format_of :username, :with => /\A[A-Za-z0-9][A-Za-z0-9_-]*\Z/
  validates_uniqueness_of :username, :case_sensitive => false

  validates_format_of :email, :with => /\A[^@]+@[^@]+\.[^@]+\Z/
  validates_uniqueness_of :email, :case_sensitive => false

  validates_presence_of :password, :on => :create

  attr_accessible :username, :email, :password, :password_confirmation,
    :email_notifications

  before_save :check_session_token

  def check_session_token
    if self.session_token.blank?
      self.session_token = Utils.random_key(60)
    end
  end

	def unread_message_count
    0
		#Message.where(:recipient_user_id => self.id, :has_been_read => 0).count
  end

	def karma
		Keystore.value_for("user:#{self.id}:karma").to_i
  end

  def initiate_password_reset_for_ip(ip)
    self.password_reset_token = Utils.random_key(60)
    self.save!

    PasswordReset.password_reset_link(self, ip).deliver
  end
end
