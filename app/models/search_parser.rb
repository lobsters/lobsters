# typed: false

require "parslet"

class SearchParser < Parslet::Parser
  rule(:space) { match('\s').repeat(1) }
  rule(:space?) { space.maybe }

  # this regexp should invert punctuation stripped by Search.strip_operators
  rule(:term) { match('[\p{Word}_\\-\']').repeat(1).as(:term) >> space? }
  rule(:quoted) { str('"') >> term.repeat(1).as(:quoted) >> str('"') >> space? }

  # reproduce the <domain> named capture in Story.URL_RE
  rule(:domain) { str("domain:") >> match("[A-Za-z_\\-\\.]").repeat(1).as(:domain) >> space? }
  # reproduce the the Tagtag format regexp
  rule(:tag) { str("tag:") >> match("[A-Za-z0-9\\-_+]").repeat(1).as(:tag) >> space? }
  rule(:domain) { str("domain:") >> match("[A-Za-z0-9_\\-\\.]").repeat(1).as(:domain) >> space? }
  rule(:url) {
    (
      str("http") >> str("s").repeat(0, 1) >> str("://") >>
      match("[A-Za-z0-9\\-_.:@/()%~?&=#]").repeat(1)
    ).as(:url) >> space?
  }
  rule(:title) { str("title:") >> (term | quoted).as(:title) >> space? }
  rule(:negated) { str("-") >> (domain | tag | quoted | term).as(:negated) >> space? }

  # catchall consumes ill-structured input
  rule(:catchall) { match("\\S").repeat(1).as(:term) >> space? }

  # ordering:
  #   title should be before quoted so that doesn't consume the quotes
  #   catchall must be last because it consumes everything
  rule(:expression) { space.maybe >> (domain | tag | title | url | term | quoted | negated | catchall).repeat(1) }
  root(:expression)
end
