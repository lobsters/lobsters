# typed: false

require "rails_helper"

RSpec.describe InboxMailbox, type: :mailbox do
  it "creates a comment on a story with a valid short id" do
    story = create(:story)
    user = create(:user)

    mail = Mail.new(
      from: user.email,
      to: "#{Rails.application.shortname}-#{user.mailing_list_token}@example.com",
      subject: "Test Comment on Story",
      in_reply_to: "story.#{story.short_id}.1@",
      body: "Testing"
    )

    mail_processed = process(mail)
    expect(mail_processed).to have_been_delivered
    story.reload
    expect(story.comments_count).to eq 1
  end

  it "creates a reply to a comment with a valid short id" do
    parent = create(:comment)
    user = create(:user)

    mail = Mail.new(
      from: user.email,
      to: "#{Rails.application.shortname}-#{user.mailing_list_token}@example.com",
      subject: "Test Comment on Comment",
      in_reply_to: "comment.#{parent.short_id}.1@",
      body: "Testing"
    )

    mail_processed = process(mail)
    expect(mail_processed).to have_been_delivered

    created_comment = Comment.where(parent_comment: parent)
    expect(created_comment).to exist
  end

  it "strips the quote from top-posting" do
    story = create(:story)
    user = create(:user)

    mail = Mail.new(
      from: user.email,
      to: "#{Rails.application.shortname}-#{user.mailing_list_token}@example.com",
      subject: "Test Comment on Story",
      in_reply_to: "story.#{story.short_id}.1@",
      body: <<~BODY
        test

        On 2025-11-20 some guy wrote:
        > quoted

        -- 
        Sent from my iPhone

      BODY
    )

    mail_processed = process(mail)
    comment = Comment.last
    expect(comment.comment).to_not include("quoted")
    expect(comment.comment).to_not include("iPhone")
  end

  it "bounces an email with an invalid in-reply-to" do
    user = create(:user)

    user.update!(mailing_list_mode: 2)

    to = "#{Rails.application.shortname}-#{user.mailing_list_token}@example.com"
    irt = "invalid@"

    mail = Mail.new(
      from: user.email,
      to: to,
      subject: "Invalid irt",
      in_reply_to: irt,
      body: "Testing"
    )

    mail_processed = process(mail)
    expect(mail_processed).to have_bounced
  end

  it "bounces an email with an invalid user token" do
    to = "#{Rails.application.shortname}-invalid@example.com"

    mail = Mail.new(
      from: "invalid@example.com",
      to: to,
      subject: "Invalid user token",
      body: "Testing"
    )

    mail_processed = process(mail)
    expect(mail_processed).to have_bounced
  end

  it "bounces an email with an empty body" do
    story = create(:story)
    user = create(:user)

    user.update!(mailing_list_mode: 2)

    to = "#{Rails.application.shortname}-#{user.mailing_list_token}@example.com"
    irt = "story.#{story.short_id}.1@"

    mail = Mail.new(
      from: user.email,
      to: to,
      subject: "Test Comment on Story",
      in_reply_to: irt,
      body: ""
    )

    mail_processed = process(mail)
    expect(mail_processed).to have_bounced

    expect(story.comments_count).to eq 0
  end
end
