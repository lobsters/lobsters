class CleanUpNullBytes < ActiveRecord::Migration[8.0]
  def change
    # sqlite doesn't accept NULL bytes in string/text columns; we have 2 comments and 1 story_text
    # that quoted material with a null byte, so I'm going to prep for #1871 by removing those
    # individual bytes

    admin = User.where(is_admin: true).first

    Comment.where("comment like '%\0%'").find_each do |comment|
      comment.comment.delete("\0")
      comment.save!

      Moderation.create!({
        comment: comment,
        moderator: admin,
        action: "deleted null byte",
        reason: "pasted material had a null byte; removing as prep for PR #1871"
      })
    end

    StoryText.where("body like '%\0%'").find_each do |st|
      st.body.delete("\0")
      st.save!

      Moderation.create!({
        story_id: st.id,
        moderator: admin,
        action: "deleted null byte",
        reason: "pasted material had a null byte; removing as prep for PR #1871"
      })
    end
  end
end
