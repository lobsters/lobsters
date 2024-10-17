# typed: false

ActiveRecordDoctor.configure do
  detector :unindexed_foreign_keys,
    ignore_columns: [
      "hats.short_id", # It's a unique key, but not a foreign key.
      "stories.twitter_id", # It's not a foreign key.
      "mastodon_apps.client_id" # It's not a foreign key.
    ]

  detector :missing_foreign_keys,
    ignore_columns: [
      "messages.short_id", # It's a unique key, but not a foreign key.
      "mastodon_apps.client_id", # It's not a foreign key.
      "stories.short_id", # It's a unique key, but not a foreign key.
      "stories.twitter_id", # It's not a foreign key.
      "stories.mastodon_id", # Not sure if it should be a foreign key.
      "hats.short_id", # It's a unique key, but not a foreign key.
      "comments.short_id", # It's a unique key, but not a foreign key.
      "comments.thread_id", # TODO: Can point to a comment or a Keystore.
    ]
end
