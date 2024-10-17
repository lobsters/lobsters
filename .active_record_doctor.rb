# typed: false

ActiveRecordDoctor.configure do
  detector :unindexed_foreign_keys,
    ignore_columns: [
      "hats.short_id", # It's a unique key, but not a foreign key.
      "stories.twitter_id", # It's not a foreign key.
      "mastodon_apps.client_id" # It's not a foreign key.
    ]
end
