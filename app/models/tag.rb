class Tag < ActiveRecord::Base
  attr_accessor :filtered_count

  scope :accessible_to, ->(user) do
    user.is_admin?? all : where(:privileged => false)
  end

  def self.all_with_filtered_counts_for(user)
    counts = TagFilter.count(:group => "tag_id")

    Tag.order(:tag).accessible_to(user).map{|t|
      t.filtered_count = counts[t.id].to_i
      t
    }
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
