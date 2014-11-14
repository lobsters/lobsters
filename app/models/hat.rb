class Hat < ActiveRecord::Base
  belongs_to :user
  belongs_to :granted_by_user,
    :class_name => "User"

  validates :user, :presence => true
  validates :granted_by_user, :presence => true

  def to_html_label
    h = "<span class=\"hat\" title=\"Granted by " <<
      "#{self.granted_by_user.username} on " <<
      "#{self.created_at.strftime("%Y-%m-%d")}\">" <<
      "<span class=\"crown\">"

    if self.link.present?
      h << "<a href=\"#{self.link}\" target=\"_blank\">"
    end

    h << self.hat

    if self.link.present?
      h << "</a>"
    end

    h << "</span></span>"

    h.html_safe
  end
end
