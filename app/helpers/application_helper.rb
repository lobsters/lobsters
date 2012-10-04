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

  def description_for(story)
    if story.markeddown_description.present?
      raw coder.encode \
        story.markeddown_description, :decimal
    else
      if story.comments.any?
        story.comments.each do |comment|
          raw coder.encode comment.comment, decimal
        end
      else
        link_to story.url
      end
    end
  end
end
