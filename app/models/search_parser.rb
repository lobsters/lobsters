# typed: false

require "parslet"

class SearchParser < Parslet::Parser
  rule(:space) { match('\s').repeat(1) }
  rule(:space?) { space.maybe }

  # this regexp should invert punctuation stripped by Search.strip_operators
  rule(:term) { match('[\p{Word}_\\-\']').repeat(1).as(:term) >> space? }
  rule(:quoted) { str('"') >> term.repeat(1).as(:quoted) >> str('"') >> space? }

  # User::VALID_USERNAME
  rule(:commenter) { str("commenter:") >> match("[@~]").repeat(0, 1) >> match("[A-Za-z0-9_\\-]").repeat(1, 24).as(:commenter) >> space? }
  # reproduce the <domain> named capture in URL_RE
  rule(:domain) { str("domain:") >> match("[A-Za-z0-9_\\-\\.]").repeat(1).as(:domain) >> space? }
  # User::VALID_USERNAME
  rule(:submitter) { str("submitter:") >> match("[@~]").repeat(0, 1) >> match("[A-Za-z0-9_\\-]").repeat(1, 24).as(:submitter) >> space? }
  # reproduce the 'validates :tag, format:' regexp from Tag
  rule(:tag) { str("tag:") >> match("[A-Za-z0-9\\-_+]").repeat(1).as(:tag) >> space? }
  rule(:title) { str("title:") >> (term | quoted).as(:title) >> space? }
  rule(:url) {
    (
      str("http") >> str("s").repeat(0, 1) >> str("://") >>
      match("[A-Za-z0-9\\-_.:@/()%~?&=#]").repeat(1)
    ).as(:url) >> space?
  }
  # User::VALID_USERNAME
  rule(:user) { match("[@~]") >> match("[A-Za-z0-9_\\-]").repeat(1, 24).as(:user) >> space? }
  rule(:negated) { str("-") >> (domain | tag | quoted | term).as(:negated) >> space? }

  # catchall consumes ill-structured input
  rule(:catchall) { match("\\S").repeat(1).as(:term) >> space? }

  rule(:expression) {
    space.maybe >> (
      commenter |
      domain |
      submitter |
      tag |
      title | # title before quoted so that doesn't consume the quotes
      url |
      user | # user must come after commenter and submitter
      # term and quoted after operators they would fail to consume
      term |
      quoted |
      negated |
      # catchall must be last because it consumes everything
      catchall
    ).repeat(1)
  }
  root(:expression)
end
