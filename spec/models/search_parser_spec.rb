# typed: false

require "rails_helper"
require "parslet/convenience" # sp.parse_with_debug("input") for tree
require "parslet/rig/rspec"

# https://mariadb.com/kb/en/full-text-index-overview/#in-boolean-mode

# support:
#   terms
#   quoted terms
#   tag:
#   domain:
#   user:
#   OR
#   stemming?
#   negate any of the above

RSpec::Matchers.define :parse_to do |expected|
  def nested_map obj, &blk
    if obj.is_a? Array
      obj.map { |o| nested_map o, &blk }
    elsif obj.is_a? Hash
      obj.transform_values { |v| nested_map v, &blk }
    else
      blk.call obj
    end
  end

  def to_primitive input
    tree = SearchParser.new.parse(input)
    nested_map(tree) { |v| v.to_s }
  end

  match do |actual|
    to_primitive(actual) == expected
  end

  failure_message do |actual|
    "expected: #{expected.inspect}\nactual:   #{to_primitive(actual).inspect}"
  end
end

describe SearchParser do
  let(:sp) { SearchParser.new }

  it "parses" do
    sp = SearchParser.new
    sp.parse("hello world")
  end

  describe "term rule" do
    it("parses single words") { expect(sp.term).to parse("research") }
    it("parses contractions") { expect(sp.term).to parse("don't") }
    it("parses snake case") { expect(sp.term).to parse("search_parser") }
    it("parses multi-word") { expect(sp.term).to parse("Spider-Man") }
    it("doesn't parse multiple words") { expect(sp.term).to_not parse("research multiple") }
    it("parses terms with numbers") { expect(sp.term).to parse("plan9") }
    it("parses terms with undescores") { expect(sp.term).to parse("foo_bar") }
    # Search#flatten_title relies on this:
    it("doesn't parse a quote") { expect(sp.term).to_not parse("a\"quote") }
  end

  describe "quoted rule" do
    it("doesn't parse empty quotes") { expect(sp.quoted).to_not parse('""') }
    it("parses word in quotes") { expect(sp.quoted).to parse('"research"') }
    it("parses multiple words") { expect(sp.quoted).to parse('"research words"') }
  end

  describe "commenter rule" do
    it("parses username") { expect(sp.commenter).to parse("commenter:alice") }
    it("parses with @") { expect(sp.commenter).to parse("commenter:@bob") }
    it("parses with ~") { expect(sp.commenter).to parse("commenter:~carol") }
    it("doesn't parse blank") { expect(sp.commenter).to_not parse("commenter:") }
  end

  describe "domain rule" do
    it("parses single") { expect(sp.domain).to parse("domain:example.com") }
    it("parses dash") { expect(sp.domain).to parse("domain:foo-bar.com") }
    it("parses numbers") { expect(sp.domain).to parse("domain:9to5mac.com") }
    it("doesn't parse blank") { expect(sp.domain).to_not parse("domain:") }
  end

  describe "submitter rule" do
    it("parses username") { expect(sp.submitter).to parse("submitter:alice") }
    it("parses with @") { expect(sp.submitter).to parse("submitter:@bob") }
    it("parses with ~") { expect(sp.submitter).to parse("submitter:~carol") }
    it("doesn't parse blank") { expect(sp.submitter).to_not parse("submitter:") }
  end

  describe "tag rule" do
    it("parses single") { expect(sp.tag).to parse("tag:practices") }
    it("parses plus") { expect(sp.tag).to parse("tag:c++") }
    it("doesn't parse blank") { expect(sp.tag).to_not parse("tag:") }
  end

  describe "url rule" do
    it("parses urls") { expect(sp.url).to parse("https://example.com/") }
    it("parses punctuation stripped from terms") { expect(sp.url).to parse("https://example.com/foo-bar&a=b") }
  end

  describe "user rule" do
    it("parses with @") { expect(sp.user).to parse("@bob") }
    it("parses with ~") { expect(sp.user).to parse("~carol") }
    it("doesn't parse blank @") { expect(sp.user).to_not parse("@") }
    it("doesn't parse emails") { expect(sp.user).to_not parse("user@example.com") }
    it("doesn't parse blank ~") { expect(sp.user).to_not parse("~") }
  end

  describe "title rule" do
    it("parses single") { expect(sp.title).to parse("title:seven") }
    it("does parse single word quote") { expect(sp.title).to parse('title:"tips"') }
    it("does parse multi word quote") { expect(sp.title).to parse('title:"for fast tests"') }
    it("doesn't parse multi word") { expect(sp.title).to_not parse("title:in 2023") }
  end

  describe "negated rule" do
    it("parses single") { expect(sp.negated).to parse("-perl") }
    it("parses quotes") { expect(sp.negated).to parse('-"perl"') }
    it("parses multiword quotes") { expect(sp.negated).to parse('-"perl rules"') }
  end

  describe "expression" do
    it("parses multiple terms") { expect(sp).to parse("research paper") }
    it("parses a term and tag") { expect(sp).to parse("research tag:pdf") }
    it("parses a tag and term") { expect(sp).to parse("tag:audio podcast") }
    it("parses multiple tags") { expect(sp).to parse("tag:pdf tag:slides") }
    it("parses with URLs") { expect(sp).to parse("https://example.com/ tag:python") }
    it("parses complex searches") { expect(sp).to parse('foo -("multi word" cat) tag:pdf') }
  end

  # debugging? remember .parse_with_debug
  describe "parse trees" do
    it "parses multiple terms" do
      expect("research").to parse_to [{term: "research"}]
    end

    it "parses a term and a tag" do
      expect("research tag:pdf").to parse_to [{term: "research"}, {tag: "pdf"}]
    end

    it "parses a tag and a term" do
      expect("tag:pdf research").to parse_to [{tag: "pdf"}, {term: "research"}]
    end

    it "parses submitters, dropping @ or ~" do
      expect("submitter:~username").to parse_to [{submitter: "username"}]
      expect("submitter:@username").to parse_to [{submitter: "username"}]
    end

    it "parses urls" do
      expect("https://example.com").to parse_to [{url: "https://example.com"}]
    end

    it "parses terms and quotes" do
      expect('scrum "hot garbage" meeting').to parse_to(
        [{term: "scrum"}, {quoted: [{term: "hot"}, {term: "garbage"}]}, {term: "meeting"}]
      )
    end
  end
end
