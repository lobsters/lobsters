class ChangeTablesToUtf8mb4 < ActiveRecord::Migration[5.1]
  def up
    return if connection.adapter_name !~ /Mysql/

    [ "comments", "invitations", "messages", "moderations", "stories", "users" ].each do |t|
      execute("alter table #{t} convert to character set utf8mb4")
    end
  end

  def down
  end
end
