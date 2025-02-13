# typed: false

module ApplicationHelper
  include TimeAgoInWords

  MAX_PAGES = 15

  def avatar_img(user, size)
    image_tag(
      user.avatar_path(size),
      srcset: "#{user.avatar_path(size)} 1x, #{user.avatar_path(size * 2)} 2x",
      class: "avatar",
      size: "#{size}x#{size}",
      alt: "#{user.username} avatar",
      loading: "lazy",
      decoding: "async"
    )
  end

  def errors_for(object)
    html = +""
    unless object.errors.blank?
      html << "<div class=\"flash-error\">"
      html << "<h2>#{pluralize(object.errors.count, "error")} prohibited this \
               #{object.class.name.downcase} from being saved</h2>"
      html << "<p>There were the problems with the following fields:</p>"
      html << "<ul>"
      object.errors.full_messages.each do |error|
        html << if error == "Comments is invalid"
          # FIXME Ugly kludge, I don't know where this validation is defined to fix the wording
          "<li>Comment is missing</li>"
        else
          "<li>#{error}</li>"
        end
      end
      html << "</ul></div>"
    end

    raw(html)
  end

  def excerpt_fragment_around_link(html, url)
    words = 8
    url = Utils.normalize(url)
    parsed = Nokogiri::HTML5.fragment(html)

    # first loop: remove other tags by replacing them with their children
    is_first_link = true
    parsed.search("*").each do |tag|
      if tag.name == "a" && Utils.normalize(tag["href"]) == url && is_first_link
        # do not remove it, just mark that we've seen it
        is_first_link = false
      else
        tag.replace(tag.children)
      end
    end
    # link not found, return start of input
    if parsed.search("a").empty?
      return parsed.to_html.split.first(words * 2).join(" ")
    end

    # merge adjacent text nodes by reparsing
    parsed = Nokogiri::HTML5.fragment(parsed.to_html)

    # locate the html tag
    index = parsed.children.find_index { |node| node.name == "a" }
    # if link hast text to the left
    if index != 0
      t = parsed.children.first.text
      parsed.children.first.replace(t.split.last(words).join(" ") + " ")
    end
    # if link has text to the right
    if index != parsed.children.count - 1
      t = parsed.children.last.text
      parsed.children.last.replace(" " + t.split.last(words).join(" "))
    end

    parsed.to_html
  end

  # limitation: this can't handle generating links based on a hash of options,
  # like { controller: ..., action: ... }
  def link_to_different_page(text, path, options = {})
    current = request.path.sub(/\/page\/\d+$/, "")
    path.sub!(/\/page\/\d+$/, "")
    options[:class] = :current_page if current == path
    link_to text, path, options
  end

  def link_post button_label, link, options = {}
    options.reverse_merge class_name: nil, confirm: nil
    render partial: "helpers/link_post", locals: {
      button_label: button_label,
      link: link,
      class_name: options[:class_name],
      confirm: options[:confirm]
    }
  end

  def page_count(record_count, entries_per_page)
    (record_count + entries_per_page - 1) / entries_per_page
  end

  def page_numbers_for_pagination(max, cur)
    if max <= MAX_PAGES
      return (1..max).to_a
    end

    pages = (cur - (MAX_PAGES / 2) + 1..cur + (MAX_PAGES / 2) - 1).to_a

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

  def possible_flag_warning(showing_user, user)
    return render partial: "users/dev_flag_warning" unless Rails.env.production?
    return unless self_or_mod(showing_user, user)

    interval = time_interval("1m")
    if FlaggedCommenters.new(interval[:param], 1.day).check_list_for(showing_user)
      render partial: "users/flag_warning", locals: {showing_user: showing_user, interval: interval}
    end
  end

  # https://discuss.rubyonrails.org/t/proposal-changing-default-value-of-open-to-true-in-the-tag-method-in-actionview-taghelper/82297/2
  def tag name = nil, options = nil, open = true, escape = true
    super
  end

  def tag_link(tag)
    link_to tag.tag, tag_path(tag), class: tag.css_class, title: tag.description
  end

  def how_long_ago_label(time)
    ago = how_long_ago(time)
    content_tag(:span, ago, title: time.strftime("%F %T %z"))
  end

  def how_long_ago_link(url, time)
    ago = how_long_ago(time)
    content_tag(:a, ago, href: url, title: time.strftime("%F %T %z"))
  end
end
