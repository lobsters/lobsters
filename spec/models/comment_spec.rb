require "rails_helper"

describe Comment do
  it "should get a short id" do
    c = create(:comment)

    expect(c.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end

  describe "hat" do
    it "can't be worn if user doesn't have that hat" do
      comment = build(:comment, hat: build(:hat))
      comment.valid?
      expect(comment.errors[:hat]).to eq(['not wearable by user'])
    end

    it "can be one of the user's hats" do
      hat = create(:hat)
      user = hat.user
      comment = create(:comment, user: user, hat: hat)
      comment.valid?
      expect(comment.errors[:hat]).to be_empty
    end
  end

  it "validates the length of short_id" do
    comment = Comment.new(short_id: "01234567890")
    expect(comment).to_not be_valid
  end

  it "is not valid without a comment" do
    comment = Comment.new(comment: nil)
    expect(comment).to_not be_valid
  end

  it "validates the length of markeddown_comment" do
    comment = build(:comment, markeddown_comment: "a" * 16_777_216)
    expect(comment).to_not be_valid
  end

  it "sends reply notification" do
    recipient = create(:user)
    recipient.settings["email_notifications"] = true
    recipient.settings["email_replies"] = true

    sender = create(:user)
    # Story under which the comments are posted.
    story = create(:story)

    # Parent comment.
    c = build(:comment, story: story, user: recipient)
    c.save # Comment needs to get an ID so it can have a child (c2).

    # Reply comment.
    c2 = build(:comment, story: story, user: sender, parent_comment: c)
    c2.save

    expect(sent_emails.size).to eq(1)
    expect(sent_emails[0].subject).to match(/Reply from #{sender.username}/)
  end

  it "sends mention notification" do
    recipient = create(:user)
    recipient.settings["email_notifications"] = true
    recipient.settings["email_mentions"] = true
    # Need to save, because deliver_mention_notifications re-fetches from DB.
    recipient.save

    sender = create(:user)
    # Story under which the comment is posted.
    story = create(:story)
    # The comment.
    c = build(:comment, story: story, user: sender, comment: "@#{recipient.username}")

    c.save
    expect(sent_emails.size).to eq(1)
    expect(sent_emails[0].subject).to match(/Mention from #{sender.username}/)
  end

  it "sends only reply notification on reply with mention" do
    # User being mentioned and replied to.
    recipient = create(:user)
    recipient.settings["email_notifications"] = true
    recipient.settings["email_mentions"] = true
    recipient.settings["email_replies"] = true
    # Need to save, because deliver_mention_notifications re-fetches from DB.
    recipient.save

    sender = create(:user)
    # The story under which the comments are posted.
    story = create(:story)
    # The parent comment.
    c = build(:comment, user: recipient, story: story)
    c.save # Comment needs to get an ID so it can have a child (c2).

    # The child comment.
    c2 = build(:comment, user: sender, story: story, parent_comment: c,
               comment: "@#{recipient.username}")
    c2.save

    expect(sent_emails.size).to eq(1)
    expect(sent_emails[0].subject).to match(/Reply from #{sender.username}/)
  end
end
