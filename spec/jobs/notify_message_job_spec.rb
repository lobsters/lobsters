require "rails_helper"

RSpec.describe NotifyMessageJob, type: :job do
  describe "message notifications" do
    it "creates & sends a message notification" do
      recipient = build(:user)
      recipient.settings["email_messages"] = true
      recipient.save!
      message = create(:message, recipient: recipient)
      NotifyMessageJob.perform_now(message)
      expect(recipient.notifications.count).to eq(1)
      expect(recipient.notifications.first.notifiable).to eq(message)
      expect(sent_emails.size).to eq(1)
      expect(sent_emails[0].subject).to match(/Private Message from #{message.author_username}/)
    end
  end
end
