# typed: false

class StoryRepository
  def initialize(user = nil, params = {})
    @user = user
    @params = params
  end

  def categories(cats)
    tagged_story_ids = Tagging.select(:story_id).where(tag_id: Tag.where(category: cats).select(:id))

    Story.base(@user).positive_ranked.where(id: tagged_story_ids).order(created_at: :desc)
  end
end
