require "spec_helper"

def m(inp, out)
  Markdowner::markdown(inp).should == out
end

describe Markdowner do
  it "converts indented text into <pre>" do
    m "  This is some\n  text.\n",
      "<p><pre>  This is some\n  text.\n</pre></p>"

    m "  blah <script>alert('hi');</script>",
      "<p><pre>  blah &lt;script&gt;alert('hi');&lt;/script&gt;\n</pre></p>"
  end

  it "converts text surrounded by * to <em>" do
    m "oh hullo *there*",
      "<p>oh hullo <em>there</em></p>"

    m "*hi*",
      "<p><em>hi</em></p>"
    
    m "* hi hello*zap zap*",
      "<p>* hi hello*zap zap*</p>"

    m "oh hullo * there*",
      "<p>oh hullo * there*</p>"

    m "  oh hullo *there*",
      "<p><pre>  oh hullo *there*\n</pre></p>"

    m "oh hullo*there*",
      "<p>oh hullo*there*</p>"
  end

  it "converts text surrounded by _ to <u>" do
    m "oh hullo _there_",
      "<p>oh hullo <u>there</u></p>"

    m "oh hullo _ there_",
      "<p>oh hullo _ there_</p>"

    m "oh hullo _there_ and *yes* i see",
      "<p>oh hullo <u>there</u> and <em>yes</em> i see</p>"
  end

  it "combines conversions" do
    m "oh _*hullo*_ there_",
      "<p>oh <u><em>hullo</em></u> there_</p>"
    
    m "oh *_hullo_* there_",
      "<p>oh <em><u>hullo</u></em> there_</p>"
    
    m "oh *[hello](http://jcs.org/)* there_",
      "<p>oh <em><a href=\"http://jcs.org/\" rel=\"nofollow\">hello</a>" <<
        "</em> there_</p>"
  end

  it "converts domain names to links" do
    m "oh hullo www.google.com",
      "<p>oh hullo <a href=\"http://www.google.com\" rel=\"nofollow\">" <<
      "www.google.com</a></p>"
  end

  it "converts urls to links" do
    # no trailing question mark
    m "do you mean http://jcs.org? or",
      "<p>do you mean <a href=\"http://jcs.org\" rel=\"nofollow\">" <<
      "jcs.org</a>? or</p>"

    m "do you mean http://jcs.org?a",
      "<p>do you mean <a href=\"http://jcs.org?a\" rel=\"nofollow\">" <<
      "jcs.org?a</a></p>"

    # no trailing dot in url
    m "i like http://jcs.org.",
      "<p>i like <a href=\"http://jcs.org\" rel=\"nofollow\">" <<
      "jcs.org</a>.</p>"
    
    m "i like http://jcs.org/goose_blah_here",
      "<p>i like <a href=\"http://jcs.org/goose_blah_here\" " <<
      "rel=\"nofollow\">jcs.org/goose_blah_here</a></p>"
  end

  it "truncates long url titles" do
    m "a long http://www.example.com/goes/here/and/this/is/a/long/" <<
      "url/which/should.get.shortened.html?because=this+will+cause+" <<
      "the+page+to+wrap&such+ok",
      "<p>a long <a href=\"http://www.example.com/goes/here/and/this/" <<
      "is/a/long/url/which/should.get.shortened.html?because=this+" <<
      "will+cause+the+page+to+wrap&amp;such+ok\" rel=\"nofollow\">" <<
      "www.example.com/goes/here/and/this/is/a/long/url/w...</a></p>"
  end

  it "converts markdown url format to links" do
    m "this is a *[link](http://example.com/)*",
      "<p>this is a <em><a href=\"http://example.com/\" rel=\"nofollow\">" <<
      "link</a></em></p>"

    m "this is a [link](http://example.com/)",
      "<p>this is a <a href=\"http://example.com/\" rel=\"nofollow\">" <<
      "link</a></p>"
  end
end
