require "rails_helper"

describe StoryRepository do
  let(:viewing_user) { create(:user) }
  let(:repo) { StoryRepository.new(viewing_user) }

  describe ".newest_by_user" do
    context "when user is viewing their own stories" do
      before do
        create(:story, user: viewing_user, title: "A story not merged")
        create(:story, user: viewing_user, title: "A merged story",
               merged_into_story: create(:story))
        create(:story, user: viewing_user, title: "A merged story by the same user",
               merged_into_story: create(:story, user: viewing_user))
      end

      it "sees their stories" do
        stories = repo.newest_by_user(viewing_user)

        expect(stories.map(&:title)).to include("A story not merged")
      end

      it "sees stories merged into another story" do
        stories = repo.newest_by_user(viewing_user)

        expect(stories.map(&:title)).to include("A merged story")
      end

      it "does not see stories merged into a story they submitted" do
        stories = repo.newest_by_user(viewing_user)

        expect(stories.map(&:title)).to_not include("A merged story by the same user")
      end
    end
  end
end
