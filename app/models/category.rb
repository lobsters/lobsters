class Category < ApplicationRecord
  has_many :tags,
           -> { order('tag asc') },
           dependent: :restrict_with_error,
           inverse_of: :category
  has_many :stories, through: :tags

  after_save :log_modifications

  attr_accessor :edit_user_id

  validates :category, length: { maximum: 25 }, presence: true,
                       uniqueness: { case_sensitive: false },
                       format: { with: /\A[A-Za-z0-9_\-]+\z/ }

  def to_param
    self.category
  end

  def log_modifications
    Moderation.create do |m|
      if self.id_previously_changed?
        m.action = 'Created new category ' +
                   self.attributes.map {|f, c| "with #{f} '#{c}'" }.join(', ')
      else
        m.action = "Updating category #{self.category}, " + self.saved_changes
          .map {|f, c| "changed #{f} from '#{c[0]}' to '#{c[1]}'" } .join(', ')
      end
      m.moderator_user_id = @edit_user_id
      m.category_id = self.id
    end
  end
end
