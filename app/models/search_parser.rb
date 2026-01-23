# typed: false

require "parslet"

# https://mariadb.com/kb/en/full-text-index-stopwords/#innodb-stopwords
MYISAM_STOPWORDS = %w[a about an are as at be by com de en for from how i in is it la of on or that the this to was what when where who will with und the www].sort_by { it.length }.reverse.freeze

class SearchParser < Parslet::Parser
  rule(:space) { match('\s').repeat(1) }
  rule(:space?) { space.maybe }

  rule(:wordchar) { match('[\p{Word}_\\-\']') }
  rule(:non_wordchar) { match('[^\p{Word}_\\-\']') }
  rule(:eof) { any.absent? }

  rule(:stopword) { Parslet::Atoms::Alternative.new(*MYISAM_STOPWORDS.map { str(it) }).as(:stopword) >> (non_wordchar | eof) >> space? }
  # this regexp should invert punctuation stripped by Search.strip_operators
  rule(:term) { wordchar.repeat(3).as(:term) >> space? }
  # can't search for short terms https://github.com/lobsters/lobsters/issues/1237
  rule(:shortword) { wordchar.repeat(1, 2).as(:shortword) >> space? }
  rule(:quoted) { str('"') >> (term | shortword).repeat(1).as(:quoted) >> str('"') >> space? }

  # User::VALID_USERNAME
  rule(:commenter) { str("commenter:") >> match("[@~]").repeat(0, 1) >> match("[A-Za-z0-9_\\-]").repeat(1, 24).as(:commenter) >> space? }
  rule(:domain) {
    str("domain:").maybe >>
      (
        (match("[a-z0-9]") >> match("[a-z0-9\\-]").repeat(1, 62) >> str(".")).repeat(1) >>
        Parslet::Atoms::Alternative.new(*FetchIanaTldsJob.tlds.sort_by { -it.length }.map { str(it) }) # Consider lengthier TLDs first because Parslet is greedy (and would match "co" before "com")
      ).as(:domain) >> space?
  }
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
      stopword |
      # term and quoted after operators they would fail to consume
      term |
      shortword |
      quoted |
      negated |
      # catchall must be last because it consumes everything
      catchall
    ).repeat(1)
  }
  root(:expression)
end
