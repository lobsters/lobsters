# typed: false

# Inlines partials into parent templates for performance.
# In production & test: once at startup; development: every request
#
# Inlining the comments/_comment partial into stories/show (bulk of our traffic!)
# gives a 25-50% speedup over 'render collection: @comment', and 80-90% speedup over looping to
# 'render partial: "_comment"'.

HEINOUS_INLINE_PARTIALS = {
  # including template filename => partial filename
}

Dir["app/views/**/*.erb"].each do |filename|
  template = File.read(filename)
  next unless template.include? "heinous_inline_partial"

  # puts "inspecting #{filename}"
  partial_match = template.match(/^<%#heinous_inline_partial\(([\w\/.]+)\)%>/)
  raise "#{filename} doesn't start a line with <%#heinous..." if partial_match.nil?
  partial_name = partial_match&.captures&.first
  HEINOUS_INLINE_PARTIALS[filename] = "app/views/" + partial_name
end
l = Logger.new($stdout)
l.warn "heinous_inline_partial initialized, found: #{HEINOUS_INLINE_PARTIALS}"

def do_heinous_inline_partial_replacement
  HEINOUS_INLINE_PARTIALS.each do |filename, partial_name|
    partial_mtime = File.mtime(partial_name)
    # puts "heinous contemplating #{filename} #{File.mtime(filename).to_i} #{partial_mtime.to_i}"
    next if File.mtime(filename) == partial_mtime
    # puts "  will replace in #{filename}"

    template = File.read(filename)
    template.sub!(/
      ^<%\#heinous_inline_partial\(([\w\/.]+)\)%>
      (.+)
      ^<%\#\/heinous_inline_partial\(([\w\/.]+)\)%>\n
      /xm) { |_match|
      raise "Template name didn't match in open and closing tags. One per file!" unless $1 == $3
      # puts "  .sub! matched, replacing"

      partial = File.read(partial_name)
      if partial.include? "heinous_inline_partial"
        raise "No nesting: #{filename} includes #{$1} which has a heinous_inline_partial"
      end
      <<~REPLACE
        <%#heinous_inline_partial(#{$1})%>
        <%# Do not edit, the content before /heinous_inline_partial comes from the named partial %>
        #{partial}
        <%#/heinous_inline_partial(#{$1})%>
      REPLACE
    }
    # puts "  writing filename #{filename}"
    File.write(filename, template)
    File.utime(partial_mtime, partial_mtime, filename)
  end
end

# run once at startup:
do_heinous_inline_partial_replacement

# see before_action in ApplicationController for development mode hook
