class ActiveRecordDoctorIncorrectLengthValidation < ActiveRecord::Migration[7.2]
  def up
    change_column :links, :url, :string, limit: 250
    change_column :invitation_requests, :memo, :string, limit: 255
    change_column :invitations, :memo, :string, limit: 255
    change_column :hat_requests, :comment, :text, limit: 65_535
    change_column :hats, :short_id, :string, limit: 10
    change_column :categories, :category, :string, limit: 25
    change_column :stories, :description, :text, limit: 65_535
    change_column :messages, :body, :text, limit: 65_535
  end

  def down
    change_column :links, :url, :string
    change_column :invitation_requests, :memo, :string
    change_column :invitations, :memo, :string
    change_column :hat_requests, :comment, :text, size: :medium
    change_column :hats, :short_id, :string
    change_column :categories, :category, :string
    change_column :stories, :description, :text
    change_column :messages, :body, :text
  end
end
