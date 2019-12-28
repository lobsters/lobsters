class Domain < ApplicationRecord
  has_many :stories # rubocop:disable Rails/HasManyOrHasOneDependent
end
