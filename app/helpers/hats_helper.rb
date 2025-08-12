# typed: false

module HatsHelper
  def styled_hat(hat)
    hl = hat.link.present? && hat.link.match(/^https?:\/\//)

    if !hl && hat.link.present?
      sanitized_link = " - #{ERB::Util.html_escape(hat.sanitized_link)}"
    end

    content_tag(:span, class: "hat hat_#{hat.hat.gsub(/[^A-Za-z0-9]/, "_").downcase}", title: "Granted #{hat.created_at.strftime("%Y-%m-%d")}#{sanitized_link if sanitized_link}") do
      concat hat_text(hat, hl)
    end
  end

  def hat_text(hat, hl)
    content_tag(:span, class: "crown") do
      if hl
        concat link_to(ERB::Util.html_escape(hat.hat), ERB::Util.html_escape(hat.link), target: "_blank", rel: "noopener")
      else
        concat ERB::Util.html_escape(hat.hat)
      end
    end
  end
end
