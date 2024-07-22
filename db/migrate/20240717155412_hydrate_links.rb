class HydrateLinks < ActiveRecord::Migration[7.1]
  def up
    Comment.where("comment like '%https://%' or comment like '%http://%'").find_each do |c|
      Link.recreate_from_comment! c
    end
    Story.where("id >= 40621").where("url is not null or (description like '%https://%' or description like '%http://%')").find_each do |s|
      Link.recreate_from_story! s
    end
  end

  def down
    Link.delete_all
  end
end
