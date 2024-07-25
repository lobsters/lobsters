# typed: false

require "rails_helper"

describe Utils do
  describe "URL_RE" do
    {
      "https://example.com" => true, # basic
      "https://e.com" => true, # short domain for smaller examples
      "https://e.com/" => true,
      "https://e.com:4000" => true,
      "https://e.com:4000/" => true,
      "https://example" => false,
      "https://example/" => false,
      "https://e.com/index.html" => true,
      "https://en.wikipedia.org/wiki/Clerks_(film)" => true, # parens ok
      "http://aaonline.fr/search.php?search&criteria[title-contains]=debian" => true, # brackets ok
      "https://e.com/?foo=bar#anchor" => true # querystring, anchor
    }.each do |input, valid|
      it "validates" do
        ret = Utils::URL_RE.match? input
        expect(ret).to eq(valid), "URL_RE.match? #{input} expected #{valid} but got #{ret}"
      end
    end
  end

  describe ".silence_streams" do
    it "is defined" do
      expect(Utils.methods).to include(:silence_stream)
    end
  end
end
