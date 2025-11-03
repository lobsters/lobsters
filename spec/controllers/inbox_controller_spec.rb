# typed: false

require "rails_helper"

describe InboxController do
  let(:author) { create(:user) }
  let(:recipient) { create(:user) }

  describe "GET all" do
    it "marks the notification and associated message as read" do
      unread_message = create(:message, recipient: recipient, author: author)
      unread_notification = recipient.notifications.create(notifiable: unread_message)
      read_message = create(:message, recipient: recipient, author: author)
      read_at = Time.utc(2025, 1, 1)
      read_notification = recipient.notifications.create(notifiable: read_message, read_at: read_at)
      stub_login_as recipient
      get :all
      unread_message.reload
      unread_notification.reload
      read_notification.reload

      # Notification read
      expect(unread_notification.read_at).to_not be_nil
      expect(unread_notification.read_at).to be > read_at

      # Already read notification reamins unchanged, ie read_at is not updated
      expect(read_notification.read_at).to eq read_at
    end

    it "marks the notification as read even if notification is not displayed" do
      unread_comment = create(:comment, user: author, comment: "@#{author.username}")
      unread_notification = author.notifications.create(notifiable: unread_comment)

      stub_login_as author
      # Disable mention notifications, so that notification is not displayed
      author.settings["inbox_mentions"] = false
      author.save!
      unread_notification.reload
      expect(unread_notification.should_display?).to eq(false)

      get :all
      unread_notification.reload
      expect(unread_notification.read_at).to_not be_nil
    end

    it "does not update read_at of notification, when notification is not displayed" do
      unread_comment = create(:comment, user: author, comment: "@#{author.username}")
      read_at = Time.utc(2025, 1, 1)
      notification = author.notifications.create(notifiable: unread_comment, read_at: read_at)

      stub_login_as author
      # Disable mention notifications, so that notification is not displayed
      author.settings["inbox_mentions"] = false
      author.save!
      notification.reload
      expect(notification.should_display?).to eq(false)

      get :all
      notification.reload
      # Already read notification remains unchanged, ie read_at is not updated
      expect(notification.read_at).to eq read_at
    end
  end
end
