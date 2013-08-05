class Tag < ActiveRecord::Base
  has_many :taggings,
    :dependent => :delete_all

  attr_accessor :filtered_count

  scope :accessible_to, ->(user) do
    user && user.is_admin?? all : where(:privileged => false)
  end

  def self.all_with_filtered_counts_for(user)
    counts = TagFilter.count(:group => "tag_id")

    Tag.order(:tag).accessible_to(user).map{|t|
      t.filtered_count = counts[t.id].to_i
      t
    }
  end

  def css_class
    "tag tag_#{self.tag}" << (self.is_media?? " tag_is_media" : "")
  end

  def valid_for?(user)
    if self.privileged?
      user.is_admin?
    else
      true
    end
  end

  def filtered_count
    @filtered_count ||= TagFilter.where(:tag_id => self.id).count
  end
end
