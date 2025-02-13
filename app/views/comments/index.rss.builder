xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom": "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title Rails.application.name + (@title.present? ? ": #{@title}" : "")
    xml.link Rails.application.root_url
    xml.tag! "atom:link", nil, href: request.original_url, rel: :self
    xml.description @title
    xml.pubDate @comments.first.created_at.rfc822
    xml.ttl 120

    @comments.each do |comment|
      xml.item do
        xml.title comment.story.title
        xml.link comment.url
        xml.guid comment.short_id_url
        xml.author "#{comment.user.username}@#{Rails.application.domain} (#{comment.user.username})"
        xml.pubDate comment.last_edited_at.rfc822
        xml.comments comment.url
        xml.description comment.markeddown_comment
      end
    end
  end
end
