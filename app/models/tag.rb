class Tag < ActiveRecord::Base
  attr_accessor :filtered_count

  def self.all_with_filtered_counts
    counts = TagFilter.count(:group => "tag_id")

    Tag.order(:tag).all.map{|t|
      t.filtered_count = counts[t.id].to_i
      t
    }
  end

  def filtered_count
    @filtered_count ||= TagFilter.where(:tag_id => self.id).count
  end
end
