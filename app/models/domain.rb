class Domain < ApplicationRecord
  has_many :stories, dependent: :destroy
end
