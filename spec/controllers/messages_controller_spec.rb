# typed: false

require "rails_helper"

describe MessagesController do
  include ActiveJob::TestHelper

  after do
    clear_enqueued_jobs
  end

  let(:recipient) { create(:user) }
  let(:sender) { create(:user) }

  describe "GET show" do
    it "marks the message's notification as read" do
      message = create(:message, recipient: recipient, author: sender)
      notification = recipient.notifications.create(notifiable: message)
      stub_login_as recipient
      get :show, params: {id: message.short_id}
      notification.reload
      expect(notification.read_at).not_to be_nil
    end
  end

  describe "POST keep_as_new" do
    it "marks the message's notification as unread" do
      message = create(:message, recipient: recipient, author: sender)
      notification = recipient.notifications.create(notifiable: message, read_at: Time.current)
      stub_login_as recipient
      post :keep_as_new, params: {message_id: message.short_id}
      notification.reload
      expect(notification.read_at).to be_nil
    end
  end

  describe "POST create" do
    it "schedules a notification job" do
      stub_login_as sender
      post :create, params: {message: {recipient_username: recipient.username, subject: "hello", body: "Private message. #{"pad " * 10}"}}
      expect(response.status).to eq(302)
      expect(NotifyMessageJob).to have_been_enqueued.exactly(:once)
    end
  end
end
