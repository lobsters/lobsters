# typed: false

require "rails_helper"

describe "normalizing urls" do
  {
    "https://example.com" => "example.com", # basic
    "http://www.e.com" => "e.com", # http + https same
    "https://e.com" => "e.com", # short domain, for easier examples
    "https://e.com/" => "e.com", # trailing slash
    "https://e.com#foo" => "e.com", # anchor
    "https://e.com/#foo" => "e.com", # trailing slash and anchor
    "https://www.e.com" => "e.com", # remove www.
    "https://www4.e.com" => "e.com", # remove www4.
    "https://web.e.com" => "web.e.com", # keep web.
    "https://foo.e.com" => "foo.e.com", # keep subdomains
    "https://e.co.uk" => "e.co.uk", # keep other TLDs
    "https://e.com/index.html" => "e.com", # remove index.html
    "https://e.com/asdf.html" => "e.com/asdf", # strip trailing .html
    "https://e.com/asdf.htm" => "e.com/asdf", # strip trailing .htm
    "https://e.com?b=2&a=1" => "e.com?a=1&b=2", # sort query args
    "https://e.com?a=1?b=2" => "e.com?a=1&b=2", # normalize ? to &
    "https://e.com?c=3&a=1?b=2&" => "e.com?a=1&b=2&c=3", # combined; trailing &
    "https://www10.org" => "www10.org", # keep www10. since org alone doesn't fully describe the domain
    "https://www10.example.org" => "example.org", # remove www10.

    "https://www.arxiv.org" => "arxiv.org",
    "https://arxiv.org/abs/1234.12345" => "arxiv.org/abs/1234.12345",
    "https://arxiv.org/pdf/1234.12345" => "arxiv.org/abs/1234.12345",
    "https://arxiv.org/abs/1234.12345.pdf" => "arxiv.org/abs/1234.12345",
    "https://arxiv.org/abs/2311.09394v2" => "arxiv.org/abs/2311.09394v2", # bug #954
    "https://arxiv.org/pdf/2311.09394v2.pdf" => "arxiv.org/abs/2311.09394v2",

    "https://www.rfc-editor.org/rfc/rfc9338.html" => "rfc-editor.org/rfc/9338",
    "https://www.rfc-editor.org/rfc/rfc9338.txt" => "rfc-editor.org/rfc/9338",
    "https://www.rfc-editor.org/rfc/rfc9338.pdf" => "rfc-editor.org/rfc/9338",
    "https://www.rfc-editor.org/rfc/rfc9338.xml" => "rfc-editor.org/rfc/9338",
    "https://www.rfc-editor.org/rfc/rfc9338" => "rfc-editor.org/rfc/9338",
    "https://www.rfc-editor.org/info/rfc9338" => "rfc-editor.org/rfc/9338",
    "https://rfc-editor.org/rfc/rfc9338.html" => "rfc-editor.org/rfc/9338",
    "https://rfc-editor.org/rfc/rfc9338.txt" => "rfc-editor.org/rfc/9338",
    "https://rfc-editor.org/rfc/rfc9338.pdf" => "rfc-editor.org/rfc/9338",
    "https://rfc-editor.org/rfc/rfc9338.xml" => "rfc-editor.org/rfc/9338",
    "https://rfc-editor.org/rfc/rfc9338" => "rfc-editor.org/rfc/9338",
    "https://rfc-editor.org/info/rfc9338" => "rfc-editor.org/rfc/9338",

    "https://youtube.com/watch?v=asdf" => "youtube.com/watch?v=asdf",
    "https://youtube.com/watch?v=asdf_123" => "youtube.com/watch?v=asdf_123",
    "https://www.youtube.com/watch?v=asdf" => "youtube.com/watch?v=asdf",
    "https://m.youtube.com/watch?v=asdf" => "youtube.com/watch?v=asdf",
    "https://youtu.be/asdf" => "youtube.com/watch?v=asdf",
    "https://youtube.com/watch?v=asdf&list=foo" => "youtube.com/watch?v=asdf",
    "https://youtube.com/playlist?list=foo" => "youtube.com/playlist?list=foo",
    "https://youtube.com/playlist?list=foo&index=1" => "youtube.com/playlist?list=foo",
    "https://youtube.com/playlist?index=1&list=foo" => "youtube.com/playlist?list=foo",

    # no exceptions on real URLs we've seen (output not particularly important)
    "http://aaonline.fr/search.php?search&criteria[title-contains]=debian" =>
      "aaonline.fr/search.php?criteria[title-contains]=debian&search",
    "https://wiki.freebsd.org/VCSWhy (" => "wiki.freebsd.org/VCSWhy ("
  }.each do |input, output|
    it "normalizes" do
      ret = Utils.normalize(input)
      expect(ret).to eq(output), "normalize(#{input}) expected #{output} but got #{ret}"
    end
  end
end
