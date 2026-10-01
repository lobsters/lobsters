# typed: false

class DeleteCommentRedirectRailsCacheEntries < ActiveRecord::Migration[8.1]
  # Rails.cache lives in the cache database, not primary, and SolidCache::Entry
  # only routes there when called through the store, so connect explicitly.
  class CacheDatabase < ActiveRecord::Base
    self.abstract_class = true
    connects_to database: {writing: :cache}
  end

  def up
    connection = CacheDatabase.connection
    connection.execute("delete from solid_cache_entries where cast(key as text) like 'c_%'")
  end

  def down
  end
end
