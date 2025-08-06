# typed: false

module HatsHelper
  def hat_html_label(hat)
    hl = hat.link.present? && hat.link.match(/^https?:\/\//)

    h = "<span class=\"hat " \
      "hat_#{hat.hat.gsub(/[^A-Za-z0-9]/, "_").downcase}\" " \
      "title=\"Granted #{hat.created_at.strftime("%Y-%m-%d")}"

    if !hl && hat.link.present?
      h << " - #{ERB::Util.html_escape(hat.sanitized_link)}"
    end

    h << "\">" \
      "<span class=\"crown\">"

    if hl
      h << "<a href=\"#{ERB::Util.html_escape(hat.link)}\" target=\"_blank\">"
    end

    h << ERB::Util.html_escape(hat.hat)

    if hl
      h << "</a>"
    end

    h << "</span></span>"

    h.html_safe
  end
end
