class ChangeTablesToUtf8mb4 < ActiveRecord::Migration
  def up
    return if !/Mysql/.match?(connection.adapter_name)

    ["comments", "invitations", "messages", "moderations", "stories", "users"].each do |t|
      execute("alter table #{t} convert to character set utf8mb4")
    end
  end

  def down
  end
end
