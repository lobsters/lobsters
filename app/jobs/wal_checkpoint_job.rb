# https://news.ycombinator.com/item?id=48954157
class WalCheckpointJob < ApplicationJob
  queue_as :default

  def perform(*args)
    checkpoint(ActiveRecord::Base.connection)
    SolidCache::Record.with_shard(:rack_attack) { checkpoint(SolidCache::Record.connection) }
  end

  def checkpoint(connection)
    # https://www.sqlite.org/pragma.html#pragma_wal_checkpoint
    stats = connection.execute("PRAGMA wal_checkpoint(NOOP)").first

    # https://www.sqlite.org/wal.html#avoiding_excessively_large_wal_files
    # > new content is appended to the WAL file until the WAL file accumulates about 1000 pages
    # > (and is thus about 4MB in size)

    # Our largest writes are inserts to story_texts, its max(length(body)) is 1.5MB, so I'm somewhat
    # arbitrarily picking a number large enough to accomodate 2 of those plus many smaller writes.
    return if stats["log"] < 5_000

    # if this actually fires it's probably a DOS attempt
    db = connection.pool.db_config.name
    Telebugs.message("WalCheckpointJob fired wal_checkpoint(TRUNCATE) on #{db}, stats #{stats}")
    connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
  end
end
