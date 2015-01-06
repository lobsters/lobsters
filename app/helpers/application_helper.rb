module ApplicationHelper
  def errors_for(object, message=nil)
    html = ""
    unless object.errors.blank?
      html << "<div class=\"flash-error\">\n"
      object.errors.full_messages.each do |error|
        html << error << "<br>"
      end
      html << "</div>\n"
    end

    raw(html)
  end

  def time_ago_in_words_label(time, options = {})
    strip_about = options.delete(:strip_about)
    ago = time_ago_in_words(time, options)

    if strip_about
      ago.gsub!(/^about /, "")
    end

    raw(label_tag(nil, ago, :title => time.strftime("%F %T %z")))
  end
end
