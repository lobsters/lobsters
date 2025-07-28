# typed: false

require "rails_helper"

describe NotificationsController do
  let(:author) { create(:user) }
  let(:recipient) { create(:user) }

  describe "GET all" do
    it "marks the notification and associate message as read" do
      unread_message = create(:message, recipient: recipient, author: author)
      unread_notification = recipient.notifications.create(notifiable: unread_message)
      stub_login_as recipient
      get :all
      unread_message.reload
      expect(unread_message.has_been_read).to eq(true)
      unread_notification.reload
      expect(unread_notification.read_at).to_not be_nil
    end
  end
end
