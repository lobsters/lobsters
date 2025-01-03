# typed: false

require "rails_helper"

RSpec.describe EmailReplyMailer, type: :mailer do
  it "has a stable message-id" do
    comment = create(:comment)
    user = comment.user

    e1 = EmailReplyMailer.reply(comment, user)
    e2 = EmailReplyMailer.reply(comment, user)
    expect(e1["Message-ID"]).to_not be_nil
    expect(e1["Message-ID"].to_s).to eq(e2["Message-ID"].to_s)
  end

  it "has parent in-reply-to and in references" do
    user = create(:user)
    comment = create(:comment)
    reply = create(:comment, parent_comment: comment)

    email = EmailReplyMailer.reply(reply, user)
    expect(email["Message-ID"].to_s).to eq("<#{reply.mailing_list_message_id}>")
    expect(email["In-Reply-To"].to_s).to eq("<#{comment.mailing_list_message_id}>")
    expect(email["References"].to_s).to include(comment.mailing_list_message_id)
    # test inconsistency - factory will create reply with different story id
    expect(email["References"].to_s).to include(reply.story.mailing_list_message_id)
  end

  it "addresses replies to receiver" do
    comment = create(:comment)
    user = comment.user
    reply = create(:comment, parent_comment: comment)

    email = EmailReplyMailer.reply(reply, user)
    expect(email.body.encoded).to match("replied to you")
  end

  it "contains message about replying from email" do
    comment = create(:comment)
    user = comment.user
    reply = create(:comment, parent_comment: comment)

    email = EmailReplyMailer.reply(reply, user)
    expect(email.body.encoded).to match("Reply to this email or continue")
  end

  it "addresses top-level story responses" do
    user = create(:story).user
    comment = create(:comment)

    email = EmailReplyMailer.reply(comment, user)
    expect(email.body.encoded).to match("replied to your story")
  end

  it "addresses story replies" do
    user = create(:story).user
    comment = create(:comment, user: create(:user, username: "alice"))
    reply = create(:comment, parent_comment: comment)

    email = EmailReplyMailer.reply(reply, user)
    expect(email.body.encoded).to match("replied to alice")
  end
end
