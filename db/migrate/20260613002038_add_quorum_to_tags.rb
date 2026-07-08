class AddQuorumToTags < ActiveRecord::Migration[8.0]
  def change
    add_column :tags, :quorum, :integer, default: 2
  end
end
