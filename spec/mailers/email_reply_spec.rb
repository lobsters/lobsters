# typed: false

require "rails_helper"

RSpec.describe EmailReply, type: :mailer do
  it "addresses replies to receiver" do
    comment = create(:comment)
    user = comment.user
    reply = create(:comment, parent_comment: comment)

    email = EmailReply.reply(reply, user)
    expect(email.body.encoded).to match("replied to you")
  end

  it "addresses top-level story responses" do
    user = create(:story).user
    comment = create(:comment)

    email = EmailReply.reply(comment, user)
    expect(email.body.encoded).to match("replied to your story")
  end

  it "addresses story replies" do
    user = create(:story).user
    comment = create(:comment, user: create(:user, username: "alice"))
    reply = create(:comment, parent_comment: comment)

    email = EmailReply.reply(reply, user)
    expect(email.body.encoded).to match("replied to alice")
  end
end
