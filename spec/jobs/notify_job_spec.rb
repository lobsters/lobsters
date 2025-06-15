require 'rails_helper'

RSpec.describe NotifyJob, type: :job do
  describe "comment notifications" do
    it "sends reply notification" do
      recipient = create(:user)
      recipient.settings["email_notifications"] = true
      recipient.settings["email_replies"] = true

      sender = create(:user)
      # Story under which the comments are posted.
      story = create(:story)

      # Parent comment.
      c = build(:comment, story: story, user: recipient)
      c.save! # Comment needs to get an ID so it can have a child (c2).

      # Reply comment.
      c2 = build(:comment, story: story, user: sender, parent_comment: c)
      c2.save!

      NotifyJob.perform_now(c2)

      expect(sent_emails.size).to eq(1)
      expect(sent_emails[0].subject).to match(/Reply from #{sender.username}/)
    end

    it "sends mention notification" do
      recipient = create(:user)
      recipient.settings["email_notifications"] = true
      recipient.settings["email_mentions"] = true
      recipient.save!

      sender = create(:user)
      c = build(:comment, user: sender, comment: "@#{recipient.username}")

      c.save!

      NotifyJob.perform_now(c)

      expect(sent_emails.size).to eq(1)
      expect(sent_emails[0].subject).to match(/Mention from #{sender.username}/)
    end

    it "also sends mentions with ~username" do
      recipient = create(:user)
      recipient.settings["email_notifications"] = true
      recipient.settings["email_mentions"] = true
      recipient.save!

      c = build(:comment, comment: "~#{recipient.username}")
      c.save!

      NotifyJob.perform_now(c)

      expect(sent_emails.size).to eq(1)
    end

    it "sends only reply notification on reply with mention" do
      # User being mentioned and replied to.
      recipient = create(:user)
      recipient.settings["email_notifications"] = true
      recipient.settings["email_mentions"] = true
      recipient.settings["email_replies"] = true
      # Need to save, because deliver_mention_notifications re-fetches from DB.
      recipient.save!

      sender = create(:user)
      # The story under which the comments are posted.
      story = create(:story)
      # The parent comment.
      c = build(:comment, user: recipient, story: story)
      c.save! # Comment needs to get an ID so it can have a child (c2).

      # The child comment.
      c2 = build(:comment, user: sender, story: story, parent_comment: c,
        comment: "@#{recipient.username}")
      c2.save!

      NotifyJob.perform_now(c2)

      expect(sent_emails.size).to eq(1)
      expect(sent_emails[0].subject).to match(/Reply from #{sender.username}/)
    end
  end
end
