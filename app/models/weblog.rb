class Weblog < ActiveRecord::Base
  belongs_to :user

  serialize :tags, Array

  def sanitized_content
    Loofah.fragment(self.content).scrub!(:strip).scrub!(:nofollow).to_s.html_safe
  end
end
