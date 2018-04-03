class Tag < ApplicationRecord
  has_many :taggings, :dependent => :delete_all
  has_many :stories, :through => :taggings

  attr_accessor :stories_count
  attr_writer :filtered_count

  scope :active, -> { where(:inactive => false) }

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

  def self.all_with_story_counts_for(user)
    counts = Tagging.group(:tag_id).count

    Tag.active.order(:tag).select {|t| t.valid_for?(user) }.map {|t|
      t.stories_count = counts[t.id].to_i
      t
    }
  end

  def css_class
    "tag tag_#{self.tag}" << (self.is_media?? " tag_is_media" : "")
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
end
