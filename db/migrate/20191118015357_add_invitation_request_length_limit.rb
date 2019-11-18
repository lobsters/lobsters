class AddInvitationRequestLengthLimit < ActiveRecord::Migration[5.2]
  def change
    change_column :invitation_requests, :name,       :string, limit: 255
    change_column :invitation_requests, :email,      :string, limit: 255
    change_column :invitation_requests, :code,       :string, limit: 255
    change_column :invitation_requests, :ip_address, :string, limit: 255
    change_column :invitation_requests, :memo,       :text,   limit: 255
  end
end
