require "rails_helper"

describe StoryRepository do
  let(:submitter) { create(:user) }
  let(:repo) { StoryRepository.new(submitter) }

  describe ".newest_by_user" do
    context "when user is viewing their own stories" do
      before do
        create(:story, user: submitter, title: "A story not merged")
        create(:story, user: submitter, title: "A merged story",
               merged_into_story: create(:story, title: "Story merged into"))
        create(:story, user: submitter, title: "A merged story by the same user",
               merged_into_story: create(:story, user: submitter))
      end

      it "sees their stories" do
        expect(story_titles_from(submitter)).to include("A story not merged")
      end

      it "sees stories that their story was merged into" do
        expect(story_titles_from(submitter)).to_not include("A merged story")
        expect(story_titles_from(submitter)).to include("Story merged into")
      end

      it "does not see stories merged into a story they submitted" do
        expect(story_titles_from(submitter)).to_not include("A merged story by the same user")
      end
    end
  end

  def story_titles_from(user)
    repo.newest_by_user(user).map(&:title)
  end
end
