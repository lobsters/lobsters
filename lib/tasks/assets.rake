# Copy assets/application-(fingerprint).js to /application.js so visitors seeing old cached pages
# get current js. Caddy sets a 1y cache-control on assets/ (implicitly invalidated by the fingerprint)
# so we avoid that by dropping it in /.
Rake::Task["assets:precompile"].enhance do
  manifest = JSON.parse(Rails.application.config.assets.manifest_path.read)
  compiled = Rails.application.config.assets.output_path.join(manifest.fetch("application.js"))
  FileUtils.cp compiled, Rails.public_path.join("application.js")
end

Rake::Task["assets:clobber"].enhance do
  FileUtils.rm_f Rails.public_path.join("application.js")
end
