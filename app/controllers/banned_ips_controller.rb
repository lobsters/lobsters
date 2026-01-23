class BannedIpsController < ApplicationController
  caches_page :index, if: CACHE_PAGE

  def index
    dir = Rails.env.production? ? "/etc/iptables" : "fixtures/iptables"
    @drops = []
    @drops = (File.read(File.join(dir, "rules.v4")) +
              File.read(File.join(dir, "rules.v6")))
      .split("\n")
      .select { it.starts_with?("-A PREROUTING") && it.ends_with?("-j DROP") }
      .map { it.delete_prefix("-A PREROUTING -s ").delete_suffix(" -j DROP") }
      .map { it.split(" -m comment --comment ") }
  rescue Errno::ENOENT
    flash[:error] = "IP ban files not found"
  rescue Errno::EACCES
    flash[:error] = "App server is missing permission to read IP ban files"
  end
end
