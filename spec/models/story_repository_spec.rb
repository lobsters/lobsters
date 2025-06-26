# typed: false

require "rails_helper"

describe StoryRepository do
  let(:submitter) { create(:user) }
  let(:repo) { StoryRepository.new(submitter) }

  describe ".tagged" do
    it "selects unique tagged stories" do
      tag1 = create(:tag)
      tag2 = create(:tag)
      story = create(:story, user: submitter, title: "A story", tags: [tag1, tag2])

      tagged = repo.tagged([tag1, tag2])

      expect(tagged.count).to be 1
      expect(tagged.first).to eq story
    end
  end

  def story_titles_from(user)
    repo.newest_by_user(user).map(&:title)
  end
end
