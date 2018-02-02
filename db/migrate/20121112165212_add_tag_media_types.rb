class AddTagMediaTypes < ActiveRecord::Migration[5.1]
  def up
    add_column :tags, :is_media, :boolean, :default => false

    [ "pdf", "video" ].each do |t|
      if tag = Tag.where(:tag => t).first
        tag.is_media = true
        tag.save
      end
    end
  end

  def down
  end
end
