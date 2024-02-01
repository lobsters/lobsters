# typed: false

# documentation: https://github.com/rails/rails/issues/46103
Rails.application.config.active_record.query_log_tags = [:controller, :action, :job]
