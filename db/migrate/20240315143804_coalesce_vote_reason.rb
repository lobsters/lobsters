class CoalesceVoteReason < ActiveRecord::Migration[7.1]
  def up
    Vote.where(reason: nil).update_all(reason: "")
    change_column :votes, :reason, :string, limit: 1, null: false, default: ""
  end

  def down
  end
end
