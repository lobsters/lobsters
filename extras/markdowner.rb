class Markdowner
  def self.to_html(text)
    if text.blank?
      return ""
    else
      html = RDiscount.new(text.to_s, :smart, :autolink, :safelink,
        :filter_styles, :filter_html, :no_image).to_html

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

      # make @username link to that user's profile
      html.gsub!(/\B\@([\w\-]+)/) do |u|
        if User.find_by_username(u[1 .. -1])
          "<a href=\"/u/#{u[1 .. -1]}\">#{u}</a>"
        else
          u
        end
      end

      html
    end
  end
end
