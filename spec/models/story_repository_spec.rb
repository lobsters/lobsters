# typed: false

require "rails_helper"

describe StoryRepository do
  let(:submitter) { create(:user) }
  let(:repo) { StoryRepository.new(submitter) }

  describe ".active" do
    it "is ordered by most-recent comment" do
      older_story = create(:story)
      newer_story = create(:story)
      older_comment = create(:comment, story: newer_story)
      newer_comment = create(:comment, story: older_story)

      expect(repo.active).to eq([newer_comment.story, older_comment.story])
    end

    it "does not show hidden stories" do
      hidden_story = create(:story)
      normal_story = create(:story)
      create(:comment, story: hidden_story)
      normal_comment = create(:comment, story: normal_story)

      HiddenStory.hide_story_for_user(hidden_story, hidden_story.user)
      hidden_story_user = User.find_by(id: hidden_story.user_id)

      hidden_story_user_repo = StoryRepository.new(hidden_story_user)
      expect(hidden_story_user_repo.active).to eq([normal_comment.story])
    end
  end

  describe ".newest_by_user" do
    context "when submitter is viewing their own stories" do
      it "sees their stories" do
        create(:story, user: submitter, title: "Own story")
        expect(story_titles_from(submitter)).to include("Own story")
      end

      it "sees their own deleted stories" do
        create(:story, user: submitter, title: "deleted story", is_deleted: 1)
        expect(story_titles_from(submitter)).to include("deleted story")
      end

      it "sees stories that were merged into others' stories" do
        by_other = create(:story, title: "other story")
        create(:story, user: submitter, title: "merged story", merged_into_story: by_other)

        expect(story_titles_from(submitter)).to include("merged story")
        expect(story_titles_from(submitter)).to_not include("other story")
      end

      it "sees their own stories merged into a story they submitted" do
        own = create(:story, user: submitter, title: "own story")
        create(:story, user: submitter, title: "merged story", merged_into_story: own)
        expect(story_titles_from(submitter)).to include("own story")
        expect(story_titles_from(submitter)).to include("merged story")
      end

      it "does not see stories by others merged into a story they submitted" do
        own = create(:story, user: submitter, title: "own story")
        create(:story, title: "by other", merged_into_story: own)
        expect(story_titles_from(submitter)).to_not include("by other")
      end
    end

    it "users don't see others' deleted stories" do
      create(:story, user: submitter, title: "deleted story", is_deleted: 1)
      expect(StoryRepository.new(nil).newest_by_user(submitter)).to_not include("deleted story")
    end
  end

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
