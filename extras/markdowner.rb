class Markdowner
  # opts[:allow_images] allows <img> tags
  # opts[:disable_profile_links] disables @username -> /u/username links

  def self.to_html(text, opts = {})
    if text.blank?
      return ""
    end

    args = [ :smart, :autolink, :safelink, :filter_styles, :filter_html ]
    if !opts[:allow_images]
      args.push :no_image
    end

    html = RDiscount.new(text.to_s, *args).to_html

    # change <h1> headings to just emphasis tags
    html.gsub!(/<(\/)?h(\d)>/) {|_| "<#{$1}strong>" }

    # fix links that got the trailing punctuation appended to move it outside
    # the link
    html.gsub!(/<a ([^>]+)([\.\!\,])">([^>]+)([\.\!\,])<\/a>/) {|_|
      if $2.to_s == $4.to_s
        "<a #{$1}\">#{$3}</a>#{$2}"
      else
        _
      end
    }

    # make links have rel=nofollow
    html.gsub!(/<a href/, "<a rel=\"nofollow\" href")

    if !opts[:disable_profile_links]
      # make @username link to that user's profile
      html.gsub!(/\B\@([\w\-]+)/) do |u|
        if User.exists?(:username => u[1 .. -1])
          "<a href=\"/u/#{u[1 .. -1]}\">#{u}</a>"
        else
          u
        end
      end
    end

    html
  end
end
