# frozen_string_literal: true

class TagFilter < ApplicationRecord
  belongs_to :tag
  belongs_to :user
end
