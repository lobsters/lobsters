# typed: false

class SuggestedTitle < ApplicationRecord
  belongs_to :story
  belongs_to :user

  validates :title, length: {maximum: 150}, presence: true
end
