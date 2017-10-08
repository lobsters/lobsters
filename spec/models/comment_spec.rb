require "spec_helper"

describe Comment do
  it "should get a short id" do
    c = Comment.make!(:comment => "hello")

    expect(c.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end

  describe 'when looking for child comments' do
    let!(:c1) { Comment.make!(comment: 'Test One', user_id: 1) }
    let!(:c2) { Comment.make!(comment: 'Test Two', user_id: 1, parent_comment_id: c1.id) }
    let!(:c3) { Comment.make!(comment: 'Test Three', user_id: 2, parent_comment_id: c1.id) }

    it 'should only get comments with children not written by the user' do
      expect(Comment.replies_to_user(1).pluck(:user_id)).not_to include(1)
    end
  end
end
