# typed: false

require "rails_helper"

describe Notification do
  describe "check_good_faith" do
    context "messages" do
      it "is good for all messages" do
        user = create(:user)
        message = create(:message)
        notification = create(:notification, user: user, notifiable: message)
        expect(notification.good_faith?).to eq(true)
      end
    end

    context "comments" do
      it "is not good for stories with more flags than upvotes" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story.id, nil, reader.id, nil)
        story.reload
        expect(story.score).to eq(1)
        expect(story.flags).to eq(1)
        comment = create(:comment, user: reader, story: story)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.good_faith?).to eq(false)
      end

      it "is good for stories with more upvotes than flags" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        expect(story.score).to eq(1)
        expect(story.flags).to eq(0)
        comment = create(:comment, user: reader, story: story)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.good_faith?).to eq(true)
      end

      it "is not good for comments with more flags than upvotes" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        comment = create(:comment, user: reader, story: story)
        Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story.id, comment.id, author.id, nil)
        comment.reload
        expect(comment.flags).to eq(1)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.good_faith?).to eq(false)
      end

      it "is not good for deleted comments" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        comment = create(:comment, user: reader, story: story, is_deleted: true)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.good_faith?).to eq(false)
      end

      it "is not good for moderated comments" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        comment = create(:comment, user: reader, story: story, is_moderated: true)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.good_faith?).to eq(false)
      end

      it "is good for other comments" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        comment = create(:comment, user: reader, story: story)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.good_faith?).to eq(true)
      end

      it "is not good for comments with parent comments with more flags than upvotes" do
        author = create(:user)
        story = create(:story, user: author)
        reader1 = create(:user)
        comment1 = create(:comment, user: reader1, story: story)
        reader2 = create(:user)
        comment2 = create(:comment, user: reader2, story: story, parent_comment: comment1)
        Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story.id, comment1.id, reader2.id, nil)
        comment1.reload
        expect(comment1.flags).to eq(1)
        notification = create(:notification, user: reader1, notifiable: comment2)
        expect(notification.good_faith?).to eq(false)
      end

      it "is not good for comments with parent comments that are deleted" do
        author = create(:user)
        story = create(:story, user: author)
        reader1 = create(:user)
        comment1 = create(:comment, user: reader1, story: story)
        reader2 = create(:user)
        comment2 = create(:comment, user: reader2, story: story, parent_comment: comment1)
        comment1.is_deleted = true
        comment1.save!
        notification = create(:notification, user: reader1, notifiable: comment2)
        expect(notification.good_faith?).to eq(false)
      end

      it "is not good for comments with parent comments that are moderated" do
        author = create(:user)
        story = create(:story, user: author)
        reader1 = create(:user)
        comment1 = create(:comment, user: reader1, story: story)
        reader2 = create(:user)
        comment2 = create(:comment, user: reader2, story: story, parent_comment: comment1)
        comment1.is_moderated = true
        comment1.save!
        notification = create(:notification, user: reader1, notifiable: comment2)
        expect(notification.good_faith?).to eq(false)
      end

      it "is good for comments with all other parent comments" do
        author = create(:user)
        story = create(:story, user: author)
        reader1 = create(:user)
        comment1 = create(:comment, user: reader1, story: story)
        reader2 = create(:user)
        comment2 = create(:comment, user: reader2, story: story, parent_comment: comment1)
        notification = create(:notification, user: reader1, notifiable: comment2)
        expect(notification.good_faith?).to eq(true)
      end

      it "is not good if the recipient has flagged any comment belonging to the author" do
        author = create(:user)
        story = create(:story, user: author)
        reader1 = create(:user)
        comment1 = create(:comment, user: reader1, story: story)
        reader2 = create(:user)
        comment2 = create(:comment, user: reader2, story: story, parent_comment: comment1)
        comment3 = create(:comment, user: reader2, story: story)
        notification = create(:notification, user: author, notifiable: comment3)
        expect(notification.good_faith?).to eq(true)
        Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story.id, comment2.id, author.id, nil)
        notification.reload
        expect(notification.good_faith?).to eq(false)
      end

      it "is not good if the recipient has hidden the story" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        comment = create(:comment, user: reader, story: story)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.good_faith?).to eq(true)
        _hidden_story = create(:hidden_story, user: author, story: story)
        notification.reload
        expect(notification.good_faith?).to eq(false)
      end

      it "is not good if the recipient has filtered the story tag" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        comment = create(:comment, user: reader, story: story)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.good_faith?).to eq(true)
        tag = create(:tag)
        story.tags << tag
        _tag_filter = TagFilter.create!(tag: tag, user: author)
        notification.reload
        expect(notification.good_faith?).to eq(false)
      end
    end
  end
end
