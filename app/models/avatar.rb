class Avatar < ApplicationRecord
  enum :type, Gravatar: 0, GitHub: 1
end
