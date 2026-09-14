# Copy fingerprinted assets to static URLs so visitors seeing old cached pages get current css and
# js. Caddy sets a 1y cache-control on assets/ (implicitly invalidated by the fingerprint) so we
# avoid that by dropping them in /.
assets = ["application.js", "application.css", "system-system.css"]

Rake::Task["assets:precompile"].enhance do
  manifest = JSON.parse(Rails.application.config.assets.manifest_path.read)
  assets.each do |name|
    compiled = Rails.application.config.assets.output_path.join(manifest.fetch(name))
    FileUtils.cp compiled, Rails.public_path.join(name)
  end
end

Rake::Task["assets:clobber"].enhance do
  assets.each { |name| FileUtils.rm_f Rails.public_path.join(name) }
end
