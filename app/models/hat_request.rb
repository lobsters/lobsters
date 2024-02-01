# typed: false

class HatRequest < ApplicationRecord
  belongs_to :user

  validates :hat, presence: true, length: {maximum: 255}
  validates :link, presence: true, length: {maximum: 255}
  validates :comment, presence: true, length: {maximum: 65_535}

  attr_accessor :rejection_comment

  def approve_by_user_for_reason!(user, reason)
    transaction do
      h = Hat.new
      h.user_id = user_id
      h.granted_by_user_id = user.id
      h.hat = hat
      h.link = link
      h.save!

      m = Message.new
      m.author_user_id = user.id
      m.recipient_user_id = user_id
      m.subject = "Your hat \"#{hat}\" has been approved"
      m.body = reason
      m.save!

      destroy!
    end
  end

  def reject_by_user_for_reason!(user, reason)
    transaction do
      m = Message.new
      m.author_user_id = user.id
      m.recipient_user_id = user_id
      m.subject = "Your request for hat \"#{hat}\" has been rejected"
      m.body = reason
      m.save!

      destroy!
    end
  end
end
