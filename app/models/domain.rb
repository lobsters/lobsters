class Domain < ApplicationRecord
  has_many :stories # rubocop:disable Rails/HasManyOrHasOneDependent

  validates :domain, presence: true
  validates :is_tracker, inclusion: { in: [true, false] }
end
