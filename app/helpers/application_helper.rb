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

  def header_links
    return @header_links if @header_links

    @header_links = {
      root_path => { :title => @cur_url == "/" ? Rails.application.name : "Home" },
      recent_path => { :title => "Recent" },
      comments_path => { :title => "Comments" },
    }

    if @user
      @header_links[threads_path] = { :title => "Your Threads" }
    end

    if @user && @user.can_submit_stories?
      @header_links[new_story_path] = { :title => "Submit Story" }
    end

    if @user
      @header_links[saved_path] = { :title => "Saved" }
    end

    @header_links[search_path] = { :title => "Search" }

    @header_links.each do |k, v|
      v[:class] ||= []

      if k == @cur_url
        v[:class].push "cur_url"
      end
    end

    @header_links
  end

  def link_to_different_page(text, path)
    if current_page? path
      text
    else
      link_to(text, path)
    end
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
    raw(content_tag(:span, ago, title: time.strftime("%F %T %z")))
  end
end
