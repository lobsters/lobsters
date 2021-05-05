# coding: utf-8
class AddDomainToStories < ActiveRecord::Migration[6.0]
  class Story < ActiveRecord::Base; end
  class Domain < ActiveRecord::Base; end

  def up
    add_reference :stories, :domain, foreign_key: true
    url_re = /\A(?<protocol>https?):\/\/(?<domain>([^\.\/]+\.)+[a-z]+)(?<port>:\d+)?(\/|\z)/i.freeze

    %w{
        1url.com 7.ly adf.ly al.ly bc.vc bit.do bit.ly bitly.com buzurl.com cur.lv
        cutt.us db.tt db.tt doiop.com ey.io filoops.info goo.gl is.gd ity.im j.mp link.tl lnkd.in ow.ly
        ph.dog po.st prettylinkpro.com q.gs qr.ae qr.net research.eligrey.com scrnch.me s.id sptfy.com
        t.co tinyarrows.com tiny.cc tinyurl.com tny.im tr.im tweez.md twitthis.com u.bb u.to v.gd
        vzturl.com wp.me ➡.ws ✩.ws x.co yep.it yourls.org zip.net
      }.each { |d| Domain.create!(domain: d, is_tracker: true) }

    Story.find_each do |s|
      match = s.url.match(url_re)
      next unless match

      name = match ? match[:domain].sub(/^www\d*\./, '') : nil
      s.domain_id = name ? Domain.where(domain: name).first_or_create.id : nil
      s.save!
    end
  end

  def down
  end
end
