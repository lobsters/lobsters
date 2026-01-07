require "rails_helper"

RSpec.describe ModMail, type: :model do
  describe "#create" do
    let(:user) { create :user }
    let(:references) { [] }
    let(:comment) { create(:comment) }

    subject { ModMail.create(recipients: [user]) }

    it "creates the ModMail" do
      mod_mail = subject
      mod_mail.comment_references << comment
      mod_mail.save
      expect(mod_mail.comment_references.first).to eq comment
      expect(mod_mail.recipients.first).to eq user
    end
  end
end
