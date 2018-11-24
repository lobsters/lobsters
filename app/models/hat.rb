class Hat < ApplicationRecord
  belongs_to :user
  belongs_to :granted_by_user, :class_name => "User", :inverse_of => false

  after_create :log_moderation

  def doff_by_user_with_reason(user, reason)
    m = Moderation.new
    m.user_id = self.user_id
    m.moderator_user_id = user.id
    m.action = "Doffed hat \"#{self.hat}\": #{reason}"
    m.save!

    self.doffed_at = Time.current
    self.save!
  end

  def destroy_by_user_with_reason(user, reason)
    m = Moderation.new
    m.user_id = self.user_id
    m.moderator_user_id = user.id
    m.action = "Revoked hat \"#{self.hat}\": #{reason}"
    m.save!

    self.destroy
  end

  def to_html_label
    hl = (self.link.present? && self.link.match(/^https?:\/\//))

    h = "<span class=\"hat " <<
        "hat_#{self.hat.gsub(/[^A-Za-z0-9]/, '_').downcase}\" " <<
        "title=\"Granted by #{self.created_at.strftime('%Y-%m-%d')}"

    if !hl && self.link.present?
      h << " - #{ERB::Util.html_escape(self.link)}"
    end

    h << "\">" <<
      "<span class=\"crown\">"

    if hl
      h << "<a href=\"#{ERB::Util.html_escape(self.link)}\" target=\"_blank\">"
    end

    h << ERB::Util.html_escape(self.hat)

    if hl
      h << "</a>"
    end

    h << "</span></span>"

    h.html_safe
  end

  def to_txt
    "(#{self.hat}) "
  end

  def log_moderation
    m = Moderation.new
    m.created_at = self.created_at
    m.user_id = self.user_id
    m.moderator_user_id = self.granted_by_user_id
    m.action = "Granted hat \"#{self.hat}\"" + (self.link.present? ?
      " (#{self.link})" : "")
    m.save
  end
end
