class Markdowner
  # opts[:allow_images] allows <img> tags
  # opts[:disable_profile_links] disables @username -> /u/username links

  def self.to_html(text, opts = {})
    if text.blank?
      return ""
    end

    args = [ :smart, :autolink, :safelink, :filter_styles, :filter_html,
      :strict ]
    if !opts[:allow_images]
      args.push :no_image
    end

    ng = Nokogiri::HTML(RDiscount.new(text.to_s, *args).to_html)

    # change <h1>, <h2>, etc. headings to just bold tags
    ng.css("h1, h2, h3, h4, h5, h6").each do |h|
      h.name = "strong"
    end

    # make links have rel=nofollow
    ng.css("a").each do |h|
      h[:rel] = "nofollow"
    end

    # XXX: t.replace(tx) unescapes HTML, so disable for now.  this probably
    # needs to split text into separate nodes and then replace the @username
    # with a proper 'a' node
if false
    unless opts[:disable_profile_links]
      # make @username link to that user's profile
      ng.search("//text()").each do |t|
        if t.parent && t.parent.name.downcase == "a"
          # don't replace inside <a>s
          next
        end

        tx = t.text.gsub(/\B\@([\w\-]+)/) do |u|
          if User.exists?(:username => u[1 .. -1])
            "<a href=\"/u/#{u[1 .. -1]}\">#{u}</a>"
          else
            u
          end
        end

        t.replace(tx)
      end
    end
end

    ng.at_css("body").inner_html
  end
end
