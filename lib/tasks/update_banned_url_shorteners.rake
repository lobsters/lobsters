# typed: false

require "open-uri"

desc "Update banned list of URL shorteners"

task update_banned_url_shorteners: :environment do
  url = "https://raw.githubusercontent.com/mayakyler/link-shorteners/refs/heads/main/js-link-shorteners/src/link-shorteners.txt"

  begin
    response = URI.parse(url).open
    content = response.read

    domains = content.split("\n").reject { |line| line.empty? || line.starts_with?("#") }

    banned_by_user = User.find_by(username: "pushcx")
    existing_domains = Domain.pluck(:domain)
    new_domains = domains - existing_domains

    if new_domains.any?
      new_domains.each do |new_domain|
        domain = Domain.find_or_create_by!(domain: new_domain)
        domain.ban_by_user_for_reason!(banned_by_user, "Used for link shortening and ad tracking")
      end

      Rails.logger.info "Successfully banned #{new_domains.size} new domains."
    else
      Rails.logger.info "No new domains to ban."
    end
  rescue OpenURI::HTTPError => e
    Rails.logger.warn "HTTP Error: #{e.message}"
  rescue => e
    Rails.logger.warn "An error occurred: #{e.message}"
  end
end
