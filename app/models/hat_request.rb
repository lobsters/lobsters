class HatRequest < ApplicationRecord
  belongs_to :user

  validates :hat, :presence => true
  validates :link, :presence => true
  validates :comment, :presence => true

  attr_accessor :rejection_comment

  def approve_by_user!(user)
    self.transaction do
      h = Hat.new
      h.user_id = self.user_id
      h.granted_by_user_id = user.id
      h.hat = self.hat
      h.link = self.link
      h.save!

      m = Message.new
      m.author_user_id = user.id
      m.recipient_user_id = self.user_id
      m.subject = "Your hat \"#{self.hat}\" has been approved"
      m.body = "This hat may now be worn when commenting.\n\n" +
               "This is an automated message."
      m.save!

      self.destroy
    end
  end

  def reject_by_user_for_reason!(user, reason)
    self.transaction do
      m = Message.new
      m.author_user_id = user.id
      m.recipient_user_id = self.user_id
      m.subject = "Your request for hat \"#{self.hat}\" has been rejected"
      m.body = reason
      m.save!

      self.destroy
    end
  end
end
