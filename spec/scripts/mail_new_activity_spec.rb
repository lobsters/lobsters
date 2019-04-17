require_relative '../../script/mail_new_activity'

describe 'EmailSender' do
  context "encoded words" do
    it "encodes text as quoted printable" do
      # Note two spaces after "Why" - following conventions in many other sites
      # additional spacing will be removed
      expect("Why  Use Pointers?".quoted_printable(true))
        .to eq("=?UTF-8?Q?Why?= =?UTF-8?Q?_Use?= =?UTF-8?Q?_Pointers=3F?=")
    end

    # https://tools.ietf.org/html/rfc2047#section-2
    # An 'encoded-word' may not be more than 75 characters long, including
    # 'charset', 'encoding', 'encoded-text', and delimiters.  If it is
    # desirable to encode more text than will fit in an 'encoded-word' of
    # 75 characters, multiple 'encoded-word's (separated by CRLF SPACE) may
    # be used.
    it 'does not allow lines longer than 75 characters' do
      string = ("foö " * 30).quoted_printable(true)
      string.lines.each {|line| expect(line.length).to be <= 75 }
    end

    it 'does not break on multibyte encoded characters' do
      q_encoded = (1..30).map { 'ö' * 5 }.join(' ').quoted_printable(true)

      without_space, *remainder = q_encoded.split("\n\t")

      expect(without_space).to eq "=?UTF-8?Q?=C3=B6=C3=B6=C3=B6=C3=B6=C3=B6?="
      expect(remainder).to all eq "=?UTF-8?Q?_=C3=B6=C3=B6=C3=B6=C3=B6=C3=B6?="
    end

    it 'handles really long words' do
      # it does not, in fact, handle long words because it would have to
      # potentially split in the middle of multibyte characters unless we
      # parsed the glyphs somehow. Current actual behavior is that it
      # simply does not line break at all.
      long_string = 'àéîöuū' * 25
      q_encoded = long_string.quoted_printable(true)
      expect(q_encoded.length).to be > long_string.length

      # This expectation exists to track current behavior - the proper behavior is:
      # q_encoded.lines.fist {|line| expect(line.length).to be <= 75 }
      expect(q_encoded.lines.count).to eq 1
      expect(q_encoded.lines.first.length).to be > 75
    end
  end
end
