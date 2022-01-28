class Markdowner
  # opts[:allow_images] allows <img> tags

  USER_MENTION = /\B(@#{User::VALID_USERNAME})/

  def self.to_html(text, opts = {})
    if text.blank?
      return ""
    end

    exts = [:tagfilter, :autolink, :strikethrough]
    escaped_text = escape_user_mention_hyphens_and_underscores(text.to_s)
    root = CommonMarker.render_doc(escaped_text, [:SMART], exts)

    walk_text_nodes(root) {|n| postprocess_text_node(n) }

    ng = Nokogiri::HTML(root.to_html([:DEFAULT], exts))

    # change <h1>, <h2>, etc. headings to just bold tags
    ng.css("h1, h2, h3, h4, h5, h6").each do |h|
      h.name = "strong"
    end

    # This should happen before adding rel=ugc to all links
    convert_images_to_links(ng) unless opts[:allow_images]

    # make links have rel=ugc
    ng.css("a").each do |h|
      h[:rel] = "ugc" unless (URI.parse(h[:href]).host.nil? rescue false)
    end

    if ng.at_css("body")
      ng.at_css("body").inner_html
    else
      ""
    end
  end

  def self.escape_user_mention_hyphens_and_underscores(text)
    text.gsub(USER_MENTION) do |match|
      match.gsub("-", "\\-")
           .gsub("_", "\\_")
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
    while node
      return unless node.string_content =~ USER_MENTION
      before, user_mention, after = $`, $1, $'

      node.string_content = before

      if User.exists?(:username => user_mention[1..-1])
        node = link_user_mention(user_mention, node)
      else
        convert_dashes(user_mention) =~ USER_MENTION
        user_mention_before_dashes, extra_after = $1, $'
        if User.exists?(:username => user_mention_before_dashes[1..-1])
          node = link_user_mention(user_mention_before_dashes, node)
          after = extra_after + after
        else
          node = unescape_user_mention_hyphens_and_underscores(user_mention, node)
        end
      end

      if after.length > 0
        remainder = CommonMarker::Node.new(:text)
        remainder.string_content = after
        node.insert_after(remainder)

        node = remainder
      else
        node = nil
      end
    end
  end

  def self.link_user_mention(user_mention, node)
    link = CommonMarker::Node.new(:link)
    link.url = Rails.application.root_url + "u/#{user_mention[1..-1]}"
    node.insert_after(link)

    link_text = CommonMarker::Node.new(:text)
    link_text.string_content = user_mention
    link.append_child(link_text)
    link
  end

  def self.convert_dashes(string)
    string.gsub("---", "—") # em dash
          .gsub("--", "–") # en dash
  end

  def self.unescape_user_mention_hyphens_and_underscores(user_mention, node)
    next_node = CommonMarker.render_doc(user_mention, [:SMART]).first_child.first_child
    after_next = next_node.next
    while next_node
      node.insert_after(next_node)
      node = next_node
      next_node = after_next
      after_next = after_next&.next
    end
    node
  end

  def self.convert_images_to_links(node)
    node.css("img").each do |img|
      link = node.create_element('a')

      link['href'], title, alt = img.attributes
        .values_at('src', 'title', 'alt')
        .map(&:to_s)

      link.content = [title, alt, link['href']].find(&:present?)

      img.replace link
    end
  end
end
