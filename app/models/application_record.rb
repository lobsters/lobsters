class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # https://stackoverflow.com/questions/50026344/composing-activerecord-scopes-with-selects
  scope :select_fix, -> { select(self.arel_table.project(Arel.star)) }
end
