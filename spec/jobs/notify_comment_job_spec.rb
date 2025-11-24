require "rails_helper"

RSpec.describe NotifyCommentJob, type: :job do
  describe "comment notifications" do
    it "sends reply notification" do
      recipient = build(:user)
      recipient.settings["email_notifications"] = true
      recipient.settings["email_replies"] = true
      recipient.save!

      sender = create(:user)
      # Story under which the comments are posted.
      story = create(:story)

      # Parent comment.
      c = build(:comment, story: story, user: recipient)
      c.save! # Comment needs to get an ID so it can have a child (c2).

      # Reply comment.
      c2 = build(:comment, story: story, user: sender, parent_comment: c)
      c2.save!

      NotifyCommentJob.perform_now(c2)

      expect(sent_emails.size).to eq(1)
      expect(sent_emails[0].subject).to match(/Reply from #{sender.username}/)
      expect(recipient.notifications.count).to eq(1)
      expect(recipient.notifications.first.notifiable).to eq(c2)
    end

    it "doesn't email if the replied-to user is hiding the story" do
      story = create(:story)

      recipient = build(:user)
      recipient.settings["email_notifications"] = true
      recipient.settings["email_replies"] = true
      recipient.save!
      parent_comment = create(:comment, story:, user: recipient)

      HiddenStory.hide_story_for_user(story, recipient)
      reply = create(:comment, story:, parent_comment:)

      NotifyCommentJob.perform_now(reply)

      expect(recipient.notifications.count).to eq(1) # exists but is filtered out
      expect(sent_emails.size).to eq(0)
    end

    it "sends mention notification" do
      recipient = build(:user)
      recipient.settings["email_notifications"] = true
      recipient.settings["email_mentions"] = true
      recipient.save!

      sender = create(:user)
      c = create(:comment, user: sender, comment: "@#{recipient.username}")

      NotifyCommentJob.perform_now(c)

      expect(sent_emails.size).to eq(1)
      expect(sent_emails[0].subject).to match(/Mention from #{sender.username}/)
      expect(recipient.notifications.count).to eq(1)
      expect(recipient.notifications.first.notifiable).to eq(c)
    end

    it "also sends mentions with ~username" do
      recipient = build(:user)
      recipient.settings["email_notifications"] = true
      recipient.settings["email_mentions"] = true
      recipient.save!

      c = build(:comment, comment: "~#{recipient.username}")
      c.save!

      NotifyCommentJob.perform_now(c)

      expect(sent_emails.size).to eq(1)
      expect(recipient.notifications.count).to eq(1)
      expect(recipient.notifications.first.notifiable).to eq(c)
    end

    it "doesn't email if the mentioned user is hiding the story" do
      story = create(:story)

      mentioned = build(:user)
      mentioned.settings["email_notifications"] = true
      mentioned.settings["email_mentions"] = true
      mentioned.save!

      HiddenStory.hide_story_for_user(story, mentioned)
      reply = create(:comment, story:, comment: "Hello @#{mentioned.username}")

      NotifyCommentJob.perform_now(reply)
      expect(mentioned.notifications.count).to eq(1) # exists but is filtered out
      expect(sent_emails.size).to eq(0)
    end

    it "sends only reply notification on reply with mention" do
      # User being mentioned and replied to.
      recipient = build(:user)
      recipient.settings["email_notifications"] = true
      recipient.settings["email_mentions"] = true
      recipient.settings["email_replies"] = true
      # Need to save, because deliver_mention_notifications re-fetches from DB.
      recipient.save!

      sender = create(:user)
      story = create(:story)
      parent = build(:comment, user: recipient, story: story)
      parent.save!

      reply = build(:comment, user: sender, story: story, parent_comment: parent,
        comment: "hi @#{recipient.username} thanks")
      reply.save!

      NotifyCommentJob.perform_now(reply)

      expect(sent_emails.size).to eq(1)
      expect(sent_emails[0].subject).to match(/Reply from #{sender.username}/)
      expect(recipient.notifications.count).to eq(1)
      expect(recipient.notifications.first.notifiable).to eq(reply)
    end
  end
end
