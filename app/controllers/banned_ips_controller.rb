class BannedIpsController < ApplicationController
  caches_page :index, if: CACHE_PAGE

  def index
    dir = Rails.env.production? ? "/etc/iptables" : "fixtures/iptables"
    @groups = {}
    @groups = (File.read(File.join(dir, "rules.v4")) +
              File.read(File.join(dir, "rules.v6")))
      .split("\n")
      .select { it.starts_with?("-A PREROUTING") && it.ends_with?("-j DROP") }
      .map { it.delete_prefix("-A PREROUTING -s ").delete_suffix(" -j DROP") }
      .map { it.split(" -m comment --comment ") }
      .group_by { |_, comment| comment_text(comment) }
      .transform_values { |drops| drops.map(&:first).uniq.sort_by { sort_ips(it) } }
  rescue Errno::ENOENT
    flash[:error] = "IP ban files not found"
  rescue Errno::EACCES
    flash[:error] = "App server is missing permission to read IP ban files"
  end

  private

  def comment_text(comment)
    return "No comment recorded" if comment.nil?
    comment.delete_prefix('"').delete_suffix('"').gsub(/\\(["\\'])/, '\1')
  end

  def sort_ips(cidr)
    ip = IPAddr.new(cidr)
    [ip.ipv4? ? 4 : 6, ip.to_i]
  end
end
