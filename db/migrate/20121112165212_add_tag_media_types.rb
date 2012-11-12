class AddTagMediaTypes < ActiveRecord::Migration
  def up
    add_column :tags, :is_media, :boolean, :default => false

    [ "pdf", "video" ].each do |t|
      if tag = Tag.find_by_tag(t)
        tag.is_media = true
        tag.save
      end
    end
  end

  def down
  end
end
