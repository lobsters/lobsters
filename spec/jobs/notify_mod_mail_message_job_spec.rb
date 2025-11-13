require "rails_helper"

RSpec.describe NotifyModMailMessageJob, type: :job do
  describe "mod mail message notifications" do
    let(:user) { create :user }
    let(:mod_mail) { create :mod_mail, recipients: [user] }
    let(:mod_mail_message) { create :mod_mail_message, :sent_by_mod, mod_mail: }

    it "creates & sends a message notification" do
      user.settings["email_messages"] = true
      user.save!
      NotifyModMailMessageJob.perform_now(mod_mail_message)
      expect(user.notifications.count).to eq(1)
      expect(user.notifications.first.notifiable).to eq(mod_mail_message)
      expect(sent_emails.size).to eq(1)
      expect(sent_emails[0].subject).to match(/Mod Mail Message from #{mod_mail_message.user.username}/)
    end
  end
end
