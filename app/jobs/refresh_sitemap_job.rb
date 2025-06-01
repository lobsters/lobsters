class RefreshSitemapJob < ApplicationJob
  queue_as :default

  def perform(*args)
    SitemapGenerator::Interpreter.run(config_file: ENV["CONFIG_FILE"], verbose: false)
  end
end
