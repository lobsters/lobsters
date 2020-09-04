require 'rails_helper'

RSpec.describe StoryText, type: :model do
  it "has a limit on the story cache field" do
    s = StoryText.new
    s.body = "Z" * 16_777_218

    s.valid?
    expect(s.errors[:body]).to eq(['is too long (maximum is 16777215 characters)'])
  end
end
