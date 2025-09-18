class ModActivity < ApplicationRecord
  belongs_to :item, polymorphic: true

  validates :item_id, uniqueness: {scope: [:item_type]}

  scope :with_item, -> {
    joins("left outer join moderations on (item_type = 'Moderation' and item_id = moderations.id)")
      .joins("left outer join mod_notes on (item_type = 'ModNote' and item_id = mod_notes.id)")
      .includes(:item)
  }
  # the moderation is about this user, or a thing they submitted
  # using this output generates a lot of 1 + n but #539 will remove that problem
  scope :user, ->(user) {
    with_item
      .joins("left outer join stories on stories.id = moderations.story_id")
      .joins("left outer join comments on comments.id = moderations.comment_id")
      # string here because rails won't allow .where() to extend across polymorphic join
      .where("
        (
          mod_notes.id is not null and
          mod_notes.user_id = :user_id
        ) or
        (
          moderations.id is not null and
          (
            moderations.user_id = :user_id or
            stories.user_id = :user_id or
            comments.user_id = :user_id
          )
        )", {user_id: user.id})
  }

  include Token

  def self.create_for!(item)
    updated_at = item.respond_to?(:updated_at) ? item.updated_at : item.created_at
    create! item: item, created_at: item.created_at, updated_at:
  end
end
