class RevertChangeTablesToUtf8mb4 < ActiveRecord::Migration[6.0]
  def up
    return if connection.adapter_name !~ /Mysql/

    [ "comments", "invitations", "messages", "moderations", "stories", "users" ].each do |t|
      execute("alter table #{t} convert to character set utf8")
    end
  end

  def down
  end
end
