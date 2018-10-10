class AddSuggestedTitles < ActiveRecord::Migration[4.2]
  def change
    create_table "suggested_titles" do |t|
      t.integer :story_id
      t.integer :user_id
      t.string :title, limit: 150, default: "", null: false, collation: "utf8mb4_general_ci"
    end
  end
end
