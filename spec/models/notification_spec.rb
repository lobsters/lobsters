# typed: false

require "rails_helper"

describe Notification do
  describe "should_display?" do
    context "messages" do
      it "should display all messages" do
        user = create(:user)
        message = create(:message)
        notification = create(:notification, user: user, notifiable: message)
        expect(notification.should_display?).to eq(true)
      end
    end

    context "mod_mail_messages" do
      it "should display all ModMail messages" do
        user = create(:user)
        mod_mail_message = create(:mod_mail_message)
        notification = create(:notification, user: user, notifiable: mod_mail_message)
        expect(notification.should_display?).to eq(true)
      end
    end

    context "comments" do
      it "should not display for comments on stories with more flags than upvotes" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story.id, nil, reader.id, nil)
        story.reload
        expect(story.score).to eq(1)
        expect(story.flags).to eq(1)
        comment = create(:comment, user: reader, story: story)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.should_display?).to eq(false)
      end

      it "should display for comments on stories with more upvotes than flags" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        expect(story.score).to eq(1)
        expect(story.flags).to eq(0)
        comment = create(:comment, user: reader, story: story)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.should_display?).to eq(true)
      end

      it "should not display for comments with more flags than upvotes" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        comment = create(:comment, user: reader, story: story)
        Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story.id, comment.id, author.id, nil)
        comment.reload
        expect(comment.flags).to eq(1)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.should_display?).to eq(false)
      end

      it "should not display for deleted comments" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        comment = create(:comment, user: reader, story: story, is_deleted: true)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.should_display?).to eq(false)
      end

      it "should not display for moderated comments" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        comment = create(:comment, user: reader, story: story, is_moderated: true)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.should_display?).to eq(false)
      end

      it "should display for other comments" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        comment = create(:comment, user: reader, story: story)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.should_display?).to eq(true)
      end

      it "respects inbox_mentions setting for mention notifications" do
        user = create(:user)
        commenter = create(:user)
        story = create(:story)
        comment = create(:comment, user: commenter, story: story, comment: "@#{user.username} hello")
        notification = create(:notification, user: user, notifiable: comment)

        user.settings["inbox_mentions"] = true
        user.save!
        expect(notification.should_display?).to eq(true)

        user.settings["inbox_mentions"] = false
        user.save!
        notification.reload
        expect(notification.should_display?).to eq(false)
      end

      it "should not display for comments with parent comments with more flags than upvotes" do
        author = create(:user)
        story = create(:story, user: author)
        reader1 = create(:user)
        comment1 = create(:comment, user: reader1, story: story)
        reader2 = create(:user)
        comment2 = create(:comment, user: reader2, story: story, parent_comment: comment1)
        Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story.id, comment1.id, create(:user), nil)
        comment1.reload
        expect(comment1.flags).to eq(1)
        notification = create(:notification, user: reader1, notifiable: comment2)
        expect(notification.should_display?).to eq(false)
      end

      it "should not display for comments with parent comments that are deleted" do
        author = create(:user)
        story = create(:story, user: author)
        reader1 = create(:user)
        comment1 = create(:comment, user: reader1, story: story)
        reader2 = create(:user)
        comment2 = create(:comment, user: reader2, story: story, parent_comment: comment1)
        comment1.is_deleted = true
        comment1.save!
        notification = create(:notification, user: reader1, notifiable: comment2)
        expect(notification.should_display?).to eq(false)
      end

      it "should not display for comments with parent comments that are moderated" do
        author = create(:user)
        story = create(:story, user: author)
        reader1 = create(:user)
        comment1 = create(:comment, user: reader1, story: story)
        reader2 = create(:user)
        comment2 = create(:comment, user: reader2, story: story, parent_comment: comment1)
        comment1.is_moderated = true
        comment1.save!
        notification = create(:notification, user: reader1, notifiable: comment2)
        expect(notification.should_display?).to eq(false)
      end

      it "should display for comments with all other parent comments" do
        author = create(:user)
        story = create(:story, user: author)
        reader1 = create(:user)
        comment1 = create(:comment, user: reader1, story: story)
        reader2 = create(:user)
        comment2 = create(:comment, user: reader2, story: story, parent_comment: comment1)
        notification = create(:notification, user: reader1, notifiable: comment2)
        expect(notification.should_display?).to eq(true)
      end

      it "should not display if the recipient has flagged any comment belonging to the author" do
        author = create(:user)
        story = create(:story, user: author)
        reader1 = create(:user)
        comment1 = create(:comment, user: reader1, story: story)
        reader2 = create(:user)
        comment2 = create(:comment, user: reader2, story: story, parent_comment: comment1)
        comment3 = create(:comment, user: reader2, story: story)
        notification = create(:notification, user: author, notifiable: comment3)
        expect(notification.should_display?).to eq(true)
        Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story.id, comment2.id, author.id, nil)
        notification.reload
        expect(notification.should_display?).to eq(false)
      end

      it "should not display if the recipient has hidden the story" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        comment = create(:comment, user: reader, story: story)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.should_display?).to eq(true)
        _hidden_story = create(:hidden_story, user: author, story: story)
        notification.reload
        expect(notification.should_display?).to eq(false)
      end

      it "should not display if the recipient has filtered the story tag" do
        author = create(:user)
        story = create(:story, user: author)
        reader = create(:user)
        comment = create(:comment, user: reader, story: story)
        notification = create(:notification, user: author, notifiable: comment)
        expect(notification.should_display?).to eq(true)
        tag = create(:tag)
        story.tags << tag
        _tag_filter = TagFilter.create!(tag: tag, user: author)
        notification.reload
        expect(notification.should_display?).to eq(false)
      end
    end
  end
end
