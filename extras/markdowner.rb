# typed: false

require "commonmarker"

class Markdowner
  USERNAME_MENTION = /\B([@~]#{User::VALID_USERNAME})\b/o

  # Rerender all markdown (#1627) cached in db columns, a pattern that predates Rails frament
  # caching and our adoption of the feature (6ce15c4f in 2025-10). As we build confidence in
  # fragment caching we should drop these columns.
  def self.rerender_db_markdown!
    Comment.all.find_each { |c| c.update_columns markeddown_comment: Markdowner.to_html(c.comment, as_of: c.created_at) }
    ModNote.all.find_each { |n| n.update_columns markeddown_note: Markdowner.to_html(n.note, as_of: n.created_at) }
    Story.where.not(description: "")
      .find_each { |s|
        s.update_columns markeddown_description: Markdowner.to_html(
          s.description,
          allow_images: s.can_have_images?,
          as_of: s.created_at
        )
      }
  end

  # allow_images: transform ![](example.com/img.jpg) to a hotlinked image; default is to print a link to the URL
  # as_of: what timestamp to add @mention links as of, because users rename; default is nil which is overridden
  #        to Time.current for newly created models passing their nil created_at
  def self.to_html(text, allow_images: false, as_of: nil)
    if text.blank?
      return ""
    end

    as_of ||= Time.current

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

    walk_text_nodes(root) { |n| link_username_mentions(n, as_of:) }

    ng = Nokogiri::HTML(root.to_html(
      options: commonmarker_options,
      plugins: {syntax_highlighter: nil}
    ))

    # change <h1>, <h2>, etc. headings to just bold tags
    ng.css("h1, h2, h3, h4, h5, h6").each do |h|
      h.name = "strong"
    end

    # This should happen before adding rel=ugc to all links
    convert_images_to_links(ng) unless allow_images

    # make links have rel=ugc
    ng.css("a").each do |h|
      h[:rel] = "ugc"
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

  def self.link_username_mentions(node, as_of:)
    # This does 1+n queries in username linkification in comments/bios because this works inorder on
    # the parse tree rather than running once over the text. Proper fix: loop to find usernames, do
    # one lookup, then loop again to manipulate the nodes for usernames that exist.

    while node
      return unless node.string_content =~ USERNAME_MENTION
      before, user, after = $`, $1, $'

      node.string_content = before

      if Username.where("created_at < ? and (? < renamed_away_at or renamed_away_at is null)", as_of, as_of).exists?(username: user[1..])
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
