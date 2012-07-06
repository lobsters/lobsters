class Markdowner
  def self.to_html(text)
    if text.blank?
      return ""
    else
      html = RDiscount.new(text.to_s, :smart, :autolink, :safelink,
        :filter_styles, :filter_html).to_html

      # change <h1> headings to just emphasis tags
      html.gsub!(/<(\/)?h(\d)>/) { |_| "<#{$1}strong>" }

      # make links have rel=nofollow
      html.gsub!(/<a href/, "<a rel=\"nofollow\" href")

      html
    end
  end
end
