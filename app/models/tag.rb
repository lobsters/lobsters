class Tag < ApplicationRecord
  belongs_to :category
  has_many :taggings, :dependent => :delete_all
  has_many :stories, :through => :taggings
  has_many :tag_filters, :dependent => :destroy
  has_many :filtering_users,
           :class_name => "User",
           :through => :tag_filters,
           :source => :user,
           :dependent => :delete_all

  after_save :log_modifications

  attr_accessor :edit_user_id, :stories_count
  attr_writer :filtered_count

  validates :tag, length: { maximum: 25 }, presence: true,
                  uniqueness: { case_sensitive: true }, format: { without: /,/ }
  validates :description, length: { maximum: 100 }
  validates :hotness_mod, inclusion: { in: -10..10 }
  validates :permit_by_new_users, :privileged, inclusion: { in: [true, false] }

  scope :active, -> { where(:active => true) }

  def to_param
    self.tag
  end

  def self.all_with_filtered_counts_for(user)
    counts = TagFilter.group(:tag_id).count

    Tag.active.order(:tag).select {|t| t.valid_for?(user) }.map {|t|
      t.filtered_count = counts[t.id].to_i
      t
    }
  end

  def category_name
    self.category && self.category.category
  end

  def category_name=(category)
    self.category = Category.find_by category: category
  end

  def css_class
    "tag tag_#{self.tag}" << (self.is_media?? " tag_is_media" : "")
  end

  def user_can_filter?(user)
    self.active? && (!self.privileged? || user.try(:is_moderator?))
  end

  def valid_for?(user)
    if self.privileged?
      !!user.try(:is_moderator?)
    else
      true
    end
  end

  def filtered_count
    @filtered_count ||= TagFilter.where(:tag_id => self.id).count
  end

  def log_modifications
    Moderation.create do |m|
      if self.id_previously_changed?
        m.action = 'Created new tag ' + self.attributes.map {|f, c| "with #{f} '#{c}'" }.join(', ')
      else
        m.action = "Updating tag #{self.tag}, " + self.saved_changes
          .map {|f, c| "changed #{f} from '#{c[0]}' to '#{c[1]}'" } .join(', ')
      end
      m.moderator_user_id = @edit_user_id
      m.tag_id = self.id
    end
  end
end
