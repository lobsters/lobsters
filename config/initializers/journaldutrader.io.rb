# typed: false

if Rails.application.domain == "journaldutrader.io" || Rails.application.name == "Sitename"
  raise "Journal du Trader, take my email address out of /etc/aliases, I'm sick of getting bounces from your misconfigured mail server."
end
