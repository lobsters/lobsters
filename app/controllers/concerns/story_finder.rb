module StoryFinder
  extend ActiveSupport::Concern

  def find_story
    story = Story.find_by(short_id: params[:story_id] || params[:id])
    # convenience to use PK (from external queries) without generally permitting enumeration:
    story ||= Story.find(params[:id]) if @user&.is_admin?

    if @user && story
      story.current_vote = Vote.find_by(
        user: @user,
        story: story.id,
        comment: nil
      ).try(:vote)
    end

    story
  end

  def find_story!
    @story = find_story
    if !@story
      raise ActiveRecord::RecordNotFound
    end
  end
end
