require 'socket'
require 'securerandom'
require 'timeout'

class FreenodeTaxonomyReader
  NICKSERV = 'NickServ!NickServ@services.'
  END_MESSGE_REGEX = /End of (.+) taxonomy|(.+) is not registered/

  def initialize(
        socket_provider: ->() { ssl_socket },
        username_provider: ->() { "lobsters-#{SecureRandom.alphanumeric(8)}" }
      )
    @socket_provider = socket_provider
    @nick = username_provider.call
  end

  def for_user(username)
    _head, *taxonomy_lines = taxonomy_for(username)

    taxonomy_lines.map do |line|
      line
        .split(':')[2,3]
        .map { |t| t.strip }
    end.to_h
  end

  private

  def taxonomy_for(username)
    taxonomy_lines = []
    s = @socket_provider.call

    Timeout.timeout(30) do
      s.write("NICK #{@nick}\r\n")
      s.write("USER #{@nick} * * :Lobsters\r\n")
      s.write("PRIVMSG NickServ :TAXONOMY #{username}\r\n")

      while line = s.gets
        next unless line.include?(":#{NICKSERV}")
        break if line.match(END_MESSGE_REGEX)
        taxonomy_lines.push(line)
      end
    end

    taxonomy_lines
  ensure
    s.close
  end

  def ssl_socket
    tcp = TCPSocket.new('chat.freenode.net', 6697)
    ssl = OpenSSL::SSL::SSLSocket.new(tcp)

    ssl.sync_close = true
    ssl.connect

    ssl
  end
end
