require "rails_helper"

RSpec.describe NotifyMessageJob, type: :job do
  describe "message notifications" do
    it "sends a message notification" do
      recipient = create(:user)
      recipient.settings["email_messages"] = true
      recipient.save!
      message = create(:message, recipient: recipient)
      NotifyMessageJob.perform_now(message)
      expect(sent_emails.size).to eq(1)
      expect(sent_emails[0].subject).to match(/Private Message from #{message.author_username}/)
    end
  end
end
