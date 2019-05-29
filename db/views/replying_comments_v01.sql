SELECT
    read_ribbons.user_id,
    comments.id as comment_id,
    read_ribbons.story_id as story_id,
    comments.parent_comment_id,
    comments.created_at as comment_created_at,
    parent_comments.user_id as parent_comment_author_id,
    comments.user_id as comment_author_id,
    stories.user_id as story_author_id,
    (read_ribbons.updated_at < comments.created_at) as is_unread,
    (select votes.vote from votes where votes.user_id = read_ribbons.user_id and votes.comment_id = comments.id) as current_vote_vote,
    (select votes.reason from votes where votes.user_id = read_ribbons.user_id and votes.comment_id = comments.id) as current_vote_reason
FROM
    read_ribbons
JOIN
    comments ON comments.story_id = read_ribbons.story_id
JOIN
    stories ON stories.id = comments.story_id
LEFT JOIN
    comments parent_comments ON parent_comments.id = comments.parent_comment_id
WHERE
    read_ribbons.is_following = 1
    AND comments.user_id != read_ribbons.user_id
    AND comments.is_deleted = FALSE
    AND comments.is_moderated = FALSE
    AND
        (parent_comments.user_id = read_ribbons.user_id
         OR (parent_comments.user_id IS NULL
         AND stories.user_id = read_ribbons.user_id))
    AND (comments.upvotes - comments.downvotes) >= 0
    AND (
      parent_comments.id IS NULL
      OR (parent_comments.upvotes - parent_comments.downvotes) >= 0
    )
    AND (CAST(stories.upvotes as signed) - CAST(stories.downvotes as signed)) >= 0
;
