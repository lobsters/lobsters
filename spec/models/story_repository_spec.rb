require "rails_helper"

describe StoryRepository do
  let(:submitter) { create(:user) }
  let(:repo) { StoryRepository.new(submitter) }

  describe '.active' do
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

      HiddenStory.hide_story_for_user(hidden_story.id, hidden_story.user_id)
      hidden_story_user = User.find_by(:id => hidden_story.user_id)

      repo = StoryRepository.new(hidden_story_user)
      expect(repo.active).to eq([normal_comment.story])
    end
  end

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
