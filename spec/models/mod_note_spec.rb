# typed: false

require "rails_helper"

describe ModNote do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :moderator) }

  it "validates the length of note" do
    mod_note = ModNote.new(user: user,
      moderator: moderator,
      note: "a" * 65_536,
      markeddown_note: "a")
    expect(mod_note).not_to be_valid
    expect(mod_note.errors.messages.dig(:note))
      .to eq(["is too long (maximum is 65535 characters)"])
  end

  it "validates the length of markeddown_note" do
    mod_note = ModNote.new(user: user,
      moderator: moderator,
      note: "a",
      markeddown_note: "a" * 65_536)
    expect(mod_note).not_to be_valid
    expect(mod_note.errors.messages.dig(:markeddown_note))
      .to eq(["is too long (maximum is 65535 characters)"])
  end

  it "validates the presence of note" do
    mod_note = ModNote.new(user: user,
      moderator: moderator,
      note: nil,
      markeddown_note: "a")
    expect(mod_note).not_to be_valid
    expect(mod_note.errors.messages.dig(:note))
      .to eq(["can't be blank"])
  end

  it "validates the presence of markeddown_note" do
    mod_note = ModNote.new(user: user,
      moderator: moderator,
      note: "a",
      markeddown_note: nil)
    expect(mod_note).not_to be_valid
    expect(mod_note.errors.messages.dig(:markeddown_note))
      .to eq(["can't be blank"])
  end
end
