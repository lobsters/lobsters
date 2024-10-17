# typed: false

ActiveRecordDoctor.configure do
  detector :unindexed_foreign_keys,
    ignore_columns: [
      # not a foreign key
      "hats.short_id",
      "stories.twitter_id",
      "mastodon_apps.client_id"
    ]

  detector :missing_foreign_keys,
    ignore_columns: [
      # not a foreign key
      "messages.short_id",
      "mastodon_apps.client_id",
      "stories.short_id",
      "stories.twitter_id",
      "hats.short_id",
      "comments.short_id",

      "stories.mastodon_id", # TODO: Not sure if it should be a foreign key.
      "comments.thread_id" # TODO: Can be a comment or a Keystore.
    ]

  detector :missing_presence_validation,
    ignore_models: [
      "ReplyingComment", # This is a view, not a real table.

      # ActiveStorage tables
      "ActiveStorage::Blob", "ActiveStorage::Attachment", "ActiveStorage::VariantRecord"
    ],
    ignore_attributes: [
      "Keystore.id" # id is not primary key.
    ]

  detector :incorrect_length_validation,
    ignore_models: [
      "ReplyingComment", # This is a view, not a real table.
      # ActiveStorage tables
      "ActiveStorage::Blob", "ActiveStorage::Attachment", "ActiveStorage::VariantRecord"
    ],
    ignore_attributes: [
      "Vote.reason", # It's using `is` constraint.
      "User.password_digest",
      "Story.description", # TODO: Is there a reason why it validates for 65_536 instead of 65_535?
      "Message.body" # TODO: Is there a reason why it validates for 65_536 instead of 65_535?
    ]
end
