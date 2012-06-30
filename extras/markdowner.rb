class Markdowner
	MAX_BARE_LINK = 50

  def self.h(str)
    # .to_str is needed because this becomes a SafeBuffer, which breaks gsub
    # https://github.com/rails/rails/issues/1555
    ERB::Util.h(str).to_str.gsub(/&lt;(\/?)(em|u|strike)&gt;/, '<\1\2>')
  end

	def self.markdown(string)
		lines = string.to_s.rstrip.split(/\r?\n/)

		out = "<p>"
		inpre = false
		lines.each do |line|
			# [ ][ ]blah -> <pre>  blah</pre>
			if line.match(/^(  |\t)/)
				if !inpre
					out << "<p><pre>"
        end

				out << ERB::Util.h(line) << "\n"
				inpre = true
				next
      elsif inpre
				out << "</pre></p>\n<p>"
				inpre = false
			end

			line = self.h(line)

			# lines starting with > are quoted
			if m = line.match(/^&gt;(.*)/)
				line = "<blockquote> " << m[1] << " </blockquote>"
      end

      lead = '\A|\s|[><]'
      trail = '[<>]|\z|\s'

			# *text* -> <em>text</em>
			line.gsub!(/(#{lead}|_|~)\*([^\* \t][^\*]*)\*(#{trail}|_|~)/) do |m|
			  "#{$1}<em>" << self.h($2) << "</em>#{$3}"
			end
      
			# _text_ -> <u>text</u>
			line.gsub!(/(#{lead}|~)_([^_ \t][^_]*)_(#{trail}|~)/) do |m|
				"#{$1}<u>" << self.h($2) << "</u>#{$3}"
			end

			# ~~text~~ -> <strike>text</strike> (from reddit)
			line.gsub!(/(#{lead})\~\~([^~ \t][^~]*)\~\~(#{trail})/) do |m|
        "#{$1}<strike>" << self.h($2) << "</strike>#{$3}"
      end

			# [link text](http://url) -> <a href="http://url">link text</a>
			line.gsub!(/(#{lead})\[([^\]]+)\]\((http(s?):\/\/[^\)]+)\)(#{trail})/i) do |m|
				"#{$1}<a href=\"" << self.h($3) << "\" rel=\"nofollow\">" <<
          self.h($2) << "</a>#{$5}"
      end

			# find bare links that are not inside tags

			# http://blah -> <a href=...>
			chunk = ""
			intag = false
			outline = ""
			line.each_byte do |n|
				c = n.chr

				if intag
					outline << c

					if c == ">"
						intag = false
						next
          end
				else
					if c == "<"
						if chunk != ""
							outline << Markdowner._linkify_text(chunk)
            end

						chunk = ""
						intag = true
						outline << c
					else
						chunk << c
				  end
        end
      end

			if chunk != ""
				outline << Markdowner._linkify_text(chunk)
      end

			out << outline << "<br>\n"
		end

		if inpre
			out << "</pre>"
    end
		
		out << "</p>"

		# multiple br's into a p
		out.gsub!(/<br>\n?<br>\n?/, "</p><p>")

		# collapse things
		out.gsub!(/<br>\n?<\/p>/, "</p>\n")
		out.gsub!(/<p>\n?<br>\n?/, "<p>")
		out.gsub!(/<p>\n?<\/p>/, "\n")
		out.gsub!(/<p>\n?<p>/, "\n<p>")
		out.gsub!(/<\/p><p>/, "</p>\n<p>")

		out.strip.force_encoding("utf-8")
	end

	def self._linkify_text(chunk)
		chunk.gsub(/
    (\A|\s|[:,])
    (http(s?):\/\/|www\.)
    ([^\s]+)/ix) do |m|
      pre = $1
      host_and_path = "#{$2 == "www." ? $2 : ""}#{$4}"
      post = $5

      # remove some chars that might be with a url at the end but aren't
      # actually part of the url
      if m = host_and_path.match(/(.*)([,\?;\!\.]+)\z/)
        host_and_path = m[1]
        post = "#{m[2]}#{post}"
      end

      url = "http#{$3}://#{host_and_path}"
      url_text = host_and_path

      if url_text.length > 50
        url_text = url_text[0 ... 50] << "..."
      end

      "#{pre}<a href=\"#{url}\" rel=\"nofollow\">#{url_text}</a>#{post}"
    end
	end
end
