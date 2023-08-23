# Inlines partials into parent templates for performance.
# In production & test: once at startup; development: every request
#
# Inlining the comments/_comment partial into stories/show (bulk of our traffic!)
# gives a 25% speedup over 'render collection: @comment'.

HEINOUS_INLINE_PARTIALS = {
  # including template => partial
}

Dir['app/views/**/*.erb'].each do |filename|
  template = File.read(filename)
  next unless template.include? 'heinous_inline_partial'

  partial_match = template.match(/^<%#heinous_inline_partial\(([\w\/\.]+)\)%>/)
  partial_name = partial_match && partial_match.captures.first
  HEINOUS_INLINE_PARTIALS[filename] = 'app/views/' + partial_name
end
l = Logger.new(STDOUT)
l.warn "heinous_inline_partial initialized, found: #{HEINOUS_INLINE_PARTIALS}"

def do_heinous_inline_partial_replacement
  HEINOUS_INLINE_PARTIALS.each do |filename, partial_name|
    partial_mtime = File.mtime(partial_name)
    #  puts "heinous contemplating #{filename} #{File.mtime(filename).to_i} #{partial_mtime.to_i}"
    next if File.mtime(filename) == partial_mtime
    # puts "  will replace in #{filename}"

    template = File.read(filename)
    template.sub!(/^<%#heinous_inline_partial\(([\w\/\.]+)\)%>(.+)^<%#\/heinous_inline_partial\(([\w\/\.]+)\)/m) { |match|
      raise "Template name didn't match in open and closing tags. One per file!" unless $1 == $3
      # puts "  .sub! matched, replacing"

      <<~REPLACE
        <%#heinous_inline_partial(#{$1})%>
        <%# Do not edit, the content until /heinous_inline_partial comes from the named partial %>
        #{File.read(partial_name)}
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
