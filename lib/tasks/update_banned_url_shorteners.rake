# typed: false

require "open-uri"

desc "Update banned list of URL shorteners"

task update_banned_url_shorteners: :environment do
  url = "https://raw.githubusercontent.com/mayakyler/link-shorteners/refs/heads/main/js-link-shorteners/src/link-shorteners.txt"

  begin
    response = URI.parse(url).open
    content = response.read

    domains = content.split("\n")

    banned_by_user = User.find_by(username: Rails.application.banned_domains_admin)
    unless banned_by_user
      abort "Couldn't find admin user #{Rails.application.banned_domains_admin} to ban domains"
    end

    existing_domains = Domain.where.not(banned_at: nil).pluck(:domain)
    new_domains = domains - existing_domains

    if new_domains.any?
      new_domains.each do |new_domain|
        domain = Domain.find_or_create_by!(domain: new_domain)
        domain.ban_by_user_for_reason!(banned_by_user, "Used for link shortening and ad tracking, see https://github.com/mayakyler/link-shorteners")
      end

      puts "Successfully banned #{new_domains.size} new domains."
    else
      puts "No new domains to ban."
    end
  rescue OpenURI::HTTPError => e
    puts "HTTP Error: #{e.message}"
  end
end
