# frozen_string_literal: true

class SuggestedTitle < ApplicationRecord
  belongs_to :story
  belongs_to :user
end
