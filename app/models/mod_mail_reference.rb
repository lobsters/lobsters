class ModMailReference < ApplicationRecord
  belongs_to :mod_mail
  belongs_to :reference, polymorphic: true

  validates :reference_type, inclusion: {in: %w[Comment Story]}, length: {maximum: 255}
end
