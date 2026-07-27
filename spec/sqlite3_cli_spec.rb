# typed: false

require "rails_helper"

describe "bin/sqlite3" do
  it "runs the sqlite3 cli built in the gem, not the OS one" do
    wrapper = Rails.root.join("bin/sqlite3").to_s
    expect(`#{wrapper} -noinit :memory: "select sqlite_version();"`.strip).to eq(SQLite3::SQLITE_VERSION)
    expect(`#{wrapper} -noinit :memory: "PRAGMA compile_options;"`).to include("ENABLE_STAT4")
  end
end

describe "rails dbconsole" do
  it "finds bin/sqlite3" do
    original_path = ENV["PATH"]

    adapter = ActiveRecord::ConnectionAdapters::SQLite3Adapter
    allow(adapter).to receive(:exec)

    adapter.find_cmd_and_exec("sqlite3", "-header")

    expect(adapter).to have_received(:exec).with(Rails.root.join("bin/sqlite3").to_s, "-header")
  ensure
    ENV["PATH"] = original_path
  end
end
