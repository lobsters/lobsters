# typed: false

class CommentRedirectCache
  SHORT_ID = /\A[0-9a-z]{6}\z/

  def self.write(short_id, target_path)
    return unless (dir = Rails.application.config.comment_redirect_cache_dir)

    FileUtils.mkdir_p(dir)
    # write + rename so Caddy never sees a partial file, like PageCache#write
    tmp = File.join(dir, ".#{SecureRandom.hex(8)}")
    File.write(tmp, target_path)
    File.rename(tmp, File.join(dir, short_id))
  rescue SystemCallError => e
    Telebugs.capture(e)
  ensure
    FileUtils.rm_f(tmp) if tmp
  end

  def self.delete(short_ids)
    return unless (dir = Rails.application.config.comment_redirect_cache_dir)

    short_ids = [short_ids].flatten.map { |id| File.join(dir, id) }
    FileUtils.rm_f(short_ids)
  end
end
