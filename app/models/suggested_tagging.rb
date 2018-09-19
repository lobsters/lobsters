# frozen_string_literal: true

class SuggestedTagging < ApplicationRecord
  belongs_to :tag
  belongs_to :story
  belongs_to :user
end
