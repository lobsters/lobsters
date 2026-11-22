require "rails_helper"

describe ModNotification do
  let!(:mod) { create(:user, :moderator) }

  describe ".notice_comment" do
    it "idempotently notices flagged comments" do
      comment = create(:comment, comment: "notice me senpai")
      create_list(:vote, 3, comment: comment, story: comment.story, vote: -1, reason: "T")
      comment.update_score_and_recalculate!(0, 0)
      comment.reload

      2.times { ModNotification.notice_comment(comment) }

      expect(ModNotification.flagged.of_comments.count).to eq(1)
    end
  end

  describe "#should_display?" do
    it "hides duplicate hotspot notifications for comments that were later flagged" do
      comment = create(:comment)
      hotspot = ModNotification.notice!(comment, "hotspot").first
      create_list(:vote, 3, comment: comment, story: comment.story, vote: -1, reason: "T")
      comment.update_score_and_recalculate!(0, 0)
      comment.reload

      expect(hotspot).not_to be_should_display
      expect(ModNotification.notice_comment(comment).first).to be_should_display
    end

    it "hides notifications for merged stories" do
      story = create(:story)
      notification = ModNotification.notice!(story, "flagged").first
      story.update_column(:merged_story_id, create(:story).id)

      expect(notification.reload).not_to be_should_display
    end
  end
end
