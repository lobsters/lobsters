class String
  def quoted_printable(encoded_word = false)
    s = [self].pack("M")

    if encoded_word
      s.split(/\r?\n/).map {|l|
        "=?UTF-8?Q?" + l.gsub(/=*$/, "").gsub('?', '=3F').tr(" ", "_") << "?="
      }.join("\n\t")
    else
      s
    end
  end

  # like ActionView::Helpers::TextHelper but preserve > and indentation when
  # wrapping lines
  def word_wrap(len)
    split("\n").collect do |line|
      if line.length <= len
        line
      elsif (m = line.match(/^(> ?|   +)(.*)/))
        ind = m[1]
        if len - ind.length <= 0
          ind = "    "
        end
        m[2].gsub(/(.{1,#{len - ind.length}})(\s+|$)/, "#{ind}\\1\n").strip
      else
        line.gsub(/(.{1,#{len}})(\s+|$)/, "\\1\n").strip
      end
    end * "\n"
  end
end
