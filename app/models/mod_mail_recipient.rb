class ModMailRecipient < ApplicationRecord
  belongs_to :mod_mail
  belongs_to :user
end
