module ApplicationHelper
  MAX_PAGES = 15

  def avatar_img(user, size)
    image_tag(user.avatar_url(size), {
      :srcset => "#{user.avatar_url(size)} 1x, " <<
        "#{user.avatar_url(size * 2)} 2x",
      :class => "avatar",
      :size => "#{size}x#{size}",
      :alt => "#{user.username} avatar" })
  end

  def break_long_words(str, len = 30)
    safe_join(str.split(" ").map{|w|
      if w.length > len
        safe_join(w.split(/(.{#{len}})/), "<wbr>".html_safe)
      else
        w
      end
    }, " ")
  end

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

  def header_links
    return @header_links if @header_links

    @header_links = {
      "/" => { :title => @cur_url == "/" ? Rails.application.name : "Home" },
      "/recent" => { :title => "Recent" },
      "/comments" => { :title => "Comments" },
    }

    if @user
      @header_links.merge!({ "/threads" => { :title => "Your Threads" } })
    end

    if @user && @user.can_submit_stories?
      @header_links.merge!({
        "/stories/new" => { :title => "Submit Story" }
      })
    end

    if @user
      @header_links.merge!({
        "/saved" => { :title => "Saved" },
      })
    end

    @header_links.merge!({
      "/search" => { :title => "Search" },
    })

    @header_links.each do |k,v|
      v[:class] ||= []

      if k == @cur_url
        v[:class].push "cur_url"
      end
    end

    @header_links
  end

  def right_header_links
    return @right_header_links if @right_header_links

    @right_header_links = {}

    if @user
      if (count = @user.unread_message_count) > 0
        @right_header_links.merge!({ "/messages" => {
          :class => [ "new_messages" ],
          :title => "#{count} New Message#{count == 1 ? "" : "s"}",
        } })
      else
        @right_header_links.merge!({
          "/messages" => { :title => "Messages" }
        })
      end

      @right_header_links.merge!({
        "/settings" => { :title => "#{@user.username} (#{@user.karma})" }
      })
    else
      @right_header_links.merge!({
        "/login" => { :title => "Login" }
      })
    end

    @right_header_links.each do |k,v|
      v[:class] ||= []

      if k == @cur_url
        v[:class].push "cur_url"
      end
    end

    @right_header_links
  end

  def page_numbers_for_pagination(max, cur)
    if max <= MAX_PAGES
      return (1 .. max).to_a
    end

    pages = (cur - (MAX_PAGES / 2) + 1 .. cur + (MAX_PAGES / 2) - 1).to_a

    while pages[0] < 1
      pages.push (pages.last + 1)
      pages.shift
    end

    while pages.last > max
      if pages[0] > 1
        pages.unshift (pages[0] - 1)
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

  def time_ago_in_words_label(time, options = {})
    ago = ""
    secs = (Time.now - time).to_i
    if secs <= 5
      ago = "just now"
    elsif secs < 60
      ago = "less than a minute ago"
    elsif secs < (60 * 60)
      mins = (secs / 60.0).floor
      ago = "#{mins} minute#{mins == 1 ? "" : "s"} ago"
    elsif secs < (60 * 60 * 48)
      hours = (secs / 60.0 / 60.0).floor
      ago = "#{hours} hour#{hours == 1 ? "" : "s"} ago"
    elsif secs < (60 * 60 * 24 * 30)
      days = (secs / 60.0 / 60.0 / 24.0).floor
      ago = "#{days} day#{days == 1 ? "" : "s"} ago"
    elsif secs < (60 * 60 * 24 * 365)
      months = (secs / 60.0 / 60.0 / 24.0 / 30.0).floor
      ago = "#{months} month#{months == 1 ? "" : "s"} ago"
    else
      years = (secs / 60.0 / 60.0 / 24.0 / 365.0).floor
      ago = "#{years} year#{years == 1 ? "" : "s"} ago"
    end

    raw(content_tag(:span, ago, :title => time.strftime("%F %T %z")))
  end
end
