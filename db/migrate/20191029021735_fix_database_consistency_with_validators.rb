class FixDatabaseConsistencyWithValidators < ActiveRecord::Migration[5.2]
    def change
        change_column_null :hat_requests, :hat, false
        change_column_null :hat_requests, :link, false
        change_column_null :hat_requests, :comment, false
        change_column_null :invitation_requests, :name, false
        change_column_null :invitation_requests, :email, false
    end
end
