# typed: false

require "commonmarker"

class Markdowner
  # opts[:allow_images] allows <img> tags

  def self.to_html(text, opts = {})
    if text.blank?
      return ""
    end

    commonmarker_options = {
      extension: {
        tagfilter: true,
        autolink: true,
        strikethrough: true,
        header_ids: nil,
        shortcodes: nil
      },
      render: {
        escape: true,
        hardbreaks: false,
        escaped_char_spans: false
      }
    }

    root = Commonmarker.parse(text.to_s, options: commonmarker_options)

    walk_text_nodes(root) { |n| postprocess_text_node(n) }

    ng = Nokogiri::HTML(root.to_html(
      options: commonmarker_options,
      plugins: {syntax_highlighter: nil}
    ))

    # change <h1>, <h2>, etc. headings to just bold tags
    ng.css("h1, h2, h3, h4, h5, h6").each do |h|
      h.name = "strong"
    end

    # This should happen before adding rel=ugc to all links
    convert_images_to_links(ng) unless opts[:allow_images]

    # make links have rel=ugc
    ng.css("a").each do |h|
      h[:rel] = "ugc" unless begin
        URI.parse(h[:href]).host.nil?
      rescue
        false
      end
    end

    if ng.at_css("body")
      ng.at_css("body").inner_html
    else
      ""
    end
  end

  def self.walk_text_nodes(node, &block)
    return if node.type == :link
    return block.call(node) if node.type == :text

    node.each do |child|
      walk_text_nodes(child, &block)
    end
  end

  def self.postprocess_text_node(node)
    # This does 1+n queries in username linkification in comments/bios because this works inorder on
    # the parse tree rather than running once over the text. Proper fix: loop to find usernames, do
    # one lookup, then loop again to manipulate the nodes for usernames that exist.

    while node
      return unless node.string_content =~ /\B(@#{User::VALID_USERNAME})/o
      before, user, after = $`, $1, $'

      node.string_content = before

      if User.exists?(username: user[1..])
        link = Commonmarker::Node.new(:link, url: Rails.application.root_url + "~#{user[1..]}")
        node.insert_after(link)

        link_text = Commonmarker::Node.new(:text)
        link_text.string_content = user
        link.append_child(link_text)

        node = link
      else
        node.string_content += user
      end

      if after.length > 0
        remainder = Commonmarker::Node.new(:text)
        remainder.string_content = after
        node.insert_after(remainder)

        node = remainder
      else
        node = nil
      end
    end
  end

  def self.convert_images_to_links(node)
    node.css("img").each do |img|
      link = node.create_element("a")

      link["href"], title, alt = img.attributes
        .values_at("src", "title", "alt")
        .map(&:to_s)

      link.content = [title, alt, link["href"]].find(&:present?)

      img.replace link
    end
  end
end
