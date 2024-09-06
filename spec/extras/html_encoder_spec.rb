# typed: false

require "rails_helper"

describe HtmlEncoder do
  it "encode all non-ascii characters" do
    expect(subject.encode("<Héllø>")).to eq "&#60;H&#233;ll&#248;&#62;"
  end

  it "decode all entities" do
    expect(subject.decode("&#60;H&#233;ll&#248;&#62;")).to eq "<Héllø>"
  end
end
