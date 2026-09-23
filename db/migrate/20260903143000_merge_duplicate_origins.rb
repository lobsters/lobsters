class MergeDuplicateOrigins < ActiveRecord::Migration[8.1]
  # might take a minute to run, not worth locking
  disable_ddl_transaction!

  def up
    Domain.where.not(selector: nil).where.not(replacement: nil).find_each do |domain|
      domain.refresh_origins!
    end

    Origin.joins(:domain).where(domains: {selector: nil}).find_each do |origin|
      Origin.reset_counters(origin.id, :stories)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
