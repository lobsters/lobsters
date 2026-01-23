# typed: false

require "rails_helper"

RSpec.describe BanNotificationMailer, type: :mailer do
  it "sets reply-to the mod's email" do
    mod = create :user, :moderator
    user = create :user

    e = BanNotificationMailer.notify(user, mod, "Spam")
    expect(e.message.reply_to).to include(mod.email)
  end
end
