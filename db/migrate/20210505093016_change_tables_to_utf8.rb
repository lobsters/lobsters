class ChangeTablesToUtf8 < ActiveRecord::Migration[6.0]
  def up
    return if connection.adapter_name !~ /Mysql/

    [ "categories", "domains", "invitation_requests", "mod_notes", "read_ribbons", "story_texts", "suggested_titles" ].each do |t|
      execute("alter table #{t} convert to character set utf8")
    end
  end

  def down
  end
end
