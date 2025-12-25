#!/usr/bin/env ruby

require "json"
require "zlib"

Request = Data.define(:ip, :is_search)

def stream_log_file(path)
  Enumerator.new do |yielder|
    print "#{File.basename(path)} "
    line_count = 0

    if path.end_with?(".gz")
      Zlib::GzipReader.open(path) do |gz|
        gz.each_line do |line|
          yielder << line
          line_count += 1
          print "." if line_count % 10_000 == 0
        end
      end
    else
      File.open(path) do |f|
        f.each_line do |line|
          yielder << line
          line_count += 1
          print "." if line_count % 10_000 == 0
        end
      end
    end

    puts
  end.lazy
end

def classify_request(line)
  return nil if line.strip.empty?

  data = JSON.parse(line)
  Request.new(
    ip: data["remote_ip"],
    is_search: data["path"].start_with?("/search?q=")
  )
rescue JSON::ParserError
  # a couple exceptions have weird encoding that doesn't parse, not worth debugging
  # warn "failed to parse: #{line}"
  nil
end

log_dir = "/home/deploy/lobsters/shared/log"
log_files = Dir.glob([
  File.join(log_dir, "action.log"),
  File.join(log_dir, "*action.log*.gz")
])

ip_counts = log_files
  .lazy
  .flat_map { |file| stream_log_file(file) }
  .map { |line| classify_request(line) }
  .compact
  .each_with_object(Hash.new { |h, k| h[k] = {search: 0, other: 0} }) do |entry, counts|
    if entry.is_search
      counts[entry.ip][:search] += 1
    else
      counts[entry.ip][:other] += 1
    end
  end

suspicious_ips = ip_counts
  .filter { |ip, counts| counts[:search] > 1_000 && counts[:other] == 0 }
  .each { |ip, counts| puts "#{ip} #{counts[:search]}" }
