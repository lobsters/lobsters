# coding: utf-8
class AddDomainToStories < ActiveRecord::Migration[5.2]
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
      }.each { |d| Domain.create!(fqdn: d, is_tracker: true) }

    Story.find_in_batches do |s|
      match = u.match(URL_RE)
      next unless match

      name = match ? match[:domain].sub(/^www\d*\./, '') : nil
      s.domain_id = name ? Domain.where(fqdn: name).first_or_create.id : nil
      s.save!
    end
  end

  def down
  end
end
