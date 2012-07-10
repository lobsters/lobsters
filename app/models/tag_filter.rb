class TagFilter < ActiveRecord::Base
  belongs_to :tag
  belongs_to :user

  attr_accessible nil
end
