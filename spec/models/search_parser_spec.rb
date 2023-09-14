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

describe SearchParser do
  let(:sp) { SearchParser.new }

  it "parses" do
    sp = SearchParser.new
    sp.parse("hello world")
  end

  # TODO test results
  # tree = SearchParser.new.parse("research tag:pdf")
  # tree.map {|h| h.transform_values(&:to_s) } == [{term: 'research'}, {tag: 'pdf'}]

  describe("term rule") do
    it("parses single words") { expect(sp.term).to parse("research") }
    it("doesn't parse multiple words") { expect(sp.term).to_not parse("research multiple") }
    it("parses terms with numbers") { expect(sp.term).to parse("plan9") }
    it("parses terms with undescores") { expect(sp.term).to parse("foo_bar") }
  end

  describe("quoted rule") do
    it("doesn't parse empty quotes") { expect(sp.quoted).to_not parse('""') }
    it("parses word in quotes") { expect(sp.quoted).to parse('"research"') }
    it("parses multiple words") { expect(sp.quoted).to parse('"research words"') }
  end

  describe("tag rule") do
    it("parses single") { expect(sp.tag).to parse("tag:practices") }
    it("parses plus") { expect(sp.tag).to parse("tag:c++") }
    it("doesn't parse blank") { expect(sp.tag).to_not parse("tag:") }
  end

  describe("domain rule") do
    it("parses single") { expect(sp.domain).to parse("domain:example.com") }
    it("parses dash") { expect(sp.domain).to parse("domain:foo-bar.com") }
    it("doesn't parse blank") { expect(sp.domain).to parse("domain:") }
  end

  describe("negated rule") do
    it("parses single") { expect(sp.negated).to parse("-perl") }
    it("parses quotes") { expect(sp.negated).to parse('-"perl"') }
    it("parses multiword quotes") { expect(sp.negated).to parse('-"perl rules"') }
  end

  describe("expression") do
    it("parses multiple terms") { expect(sp).to parse("research paper") }
    it("parses a term and tag") { expect(sp).to parse("research tag:pdf") }
    it("parses a tag and term") { expect(sp).to parse("tag:audio podcast") }
    it("parses multiple tags") { expect(sp).to parse("tag:pdf tag:slides") }
    it("parses complex searches") { expect(sp).to parse('foo -("multi word" cat) tag:pdf') }
  end
end
