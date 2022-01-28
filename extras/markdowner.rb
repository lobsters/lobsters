class Markdowner
  # opts[:allow_images] allows <img> tags

  USER_MENTION = /\B(@#{User::VALID_USERNAME})/

  def self.to_html(text, opts = {})
    if text.blank?
      return ""
    end

    exts = [:tagfilter, :autolink, :strikethrough]
    root = CommonMarker.render_doc(text.to_s, [:SMART], exts)

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

  def self.walk_text_nodes(node, &block)
    return if node.type == :link
    return block.call(node) if node.type == :text

    node.each do |child|
      walk_text_nodes(child, &block)
    end
  end

  def self.postprocess_text_node(node)
    while node
      return unless detect_user_mention(node)
      before, mention, after = rm_markdown_from_user_mention(node)
      node.string_content = before
      link = CommonMarker::Node.new(:link)
      link.url = Rails.application.root_url + "u/#{mention[1..-1]}"
      node.insert_after(link)

      link_text = CommonMarker::Node.new(:text)
      link_text.string_content = mention
      link.append_child(link_text)

      node = link

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

  def self.detect_user_mention(node)
    return nil unless rm_dashes(node.string_content) =~ USER_MENTION
    collected_user_mention, after = $1, $'

    26.times do
      break unless after.empty? && (node.next && node.next.type == :emph)
      node = node.next
      # node.to_plaintext.chomp works for :emph or :text nodes, unlike node.string_content
      if "_#{rm_dashes(node.to_plaintext.chomp)}_" =~ /\A#{User::VALID_USERNAME_CHARACTER}+/
        user_continued, after = $&, $'
        collected_user_mention += user_continued
      else
        break
      end
    end

    user_mention, after = mention_and_after_of_existing_user(collected_user_mention, after)
    user_mention
  end

  def self.mention_and_after_of_existing_user(mention, after)
    if User.exists?(username: mention[1..-1])
      return [mention, after]
    else
      convert_dashes(mention) =~ USER_MENTION
      mention_before_dashes, extra_after = $1, $'
      if User.exists?(username: mention_before_dashes[1..-1])
        return [mention_before_dashes, extra_after + after]
      end
    end
  end

  def self.rm_markdown_from_user_mention(node)
    26.times do
      rm_dashes(node.string_content) =~ USER_MENTION
      before, mention, after = $`, $1, $'
      unless after.empty? && (node.next && node.next.type == :emph)
        mention, after = mention_and_after_of_existing_user(mention, after)
        return [before, mention, after]
      end
      adjoining_emph = "_#{node.next.to_plaintext.chomp}_"
      node.string_content += adjoining_emph
      node.next.delete
      if node.type == :text && node.next&.type == :text
        node.string_content += node.next.string_content
        node.next.delete
      end
    end
  end

  def self.rm_dashes(string)
    string.gsub("—", "---") # em dash
          .gsub("–", "--") # en dash
  end

  def self.convert_dashes(string)
    string.gsub("---", "—") # em dash
          .gsub("--", "–") # en dash
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
