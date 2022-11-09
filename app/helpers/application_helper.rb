module ApplicationHelper
  include TimeAgoInWords

  MAX_PAGES = 15

  def avatar_img(user, size)
    image_tag(
      user.avatar_path(size),
      :srcset => "#{user.avatar_path(size)} 1x, #{user.avatar_path(size * 2)} 2x",
      :class => "avatar",
      :size => "#{size}x#{size}",
      :alt => "#{user.username} avatar",
      :loading => "lazy",
      :decoding => "async",
    )
  end

  def errors_for(object)
    html = ""
    unless object.errors.blank?
      html << "<div class=\"flash-error\">"
      html << "<h2>#{pluralize(object.errors.count, 'error')} prohibited this \
               #{object.class.name.downcase} from being saved</h2>"
      html << "<p>There were the problems with the following fields:</p>"
      html << "<ul>"
      object.errors.full_messages.each do |error|
        html << "<li>#{error}</li>"
      end
      html << "</ul></div>"
    end

    raw(html)
  end

  # limitation: this can't handle generating links based on a hash of options,
  # like { controller: ..., action: ... }
  def link_to_different_page(text, path, options = {})
    current = request.path.sub(/\/page\/\d+$/, '')
    path.sub!(/\/page\/\d+$/, '')
    options[:class] = :current_page if current == path
    link_to text, path, options
  end

  def link_post button_label, link, options = {}
    options.reverse_merge class_name: nil, confirm: nil
    render partial: 'helpers/link_post', locals: {
      button_label: button_label,
      link: link,
      class_name: options[:class_name],
      confirm: options[:confirm],
    }
  end

  def page_numbers_for_pagination(max, cur)
    if max <= MAX_PAGES
      return (1 .. max).to_a
    end

    pages = (cur - (MAX_PAGES / 2) + 1 .. cur + (MAX_PAGES / 2) - 1).to_a

    while pages[0] < 1
      pages.push pages.last + 1
      pages.shift
    end

    while pages.last > max
      if pages[0] > 1
        pages.unshift pages[0] - 1
      end
      pages.pop
    end

    if pages[0] != 1
      if pages[0] != 2
        pages.unshift "..."
      end
      pages.unshift 1
    end

    if pages.last != max
      if pages.last != max - 1
        pages.push "..."
      end
      pages.push max
    end

    pages
  end

  def tag_link(tag)
    link_to tag.tag, tag_path(tag), class: tag.css_class, title: tag.description
  end

  def time_ago_in_words_label(time)
    ago = time_ago_in_words(time)
    content_tag(:span, ago, title: time.strftime("%F %T %z"))
  end
end
