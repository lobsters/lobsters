# typed: false

ActiveRecordDoctor.configure do
  detector :unindexed_foreign_keys,
    ignore_columns: [
      "hats.short_id",
      "mastodon_apps.client_id",
      "stories.twitter_id"
    ]

  detector :missing_foreign_keys,
    ignore_columns: [
      "comments.short_id",
      "comments.thread_id",
      "hats.short_id",
      "mastodon_apps.client_id",
      "messages.short_id",
      "stories.mastodon_id",
      "stories.short_id",
      "stories.twitter_id"
    ]

  detector :missing_presence_validation,
    ignore_models: [
      "ActiveStorage::Attachment",
      "ActiveStorage::Blob",
      "ActiveStorage::VariantRecord",
      "ReplyingComment"
    ],
    ignore_attributes: [
      "Keystore.id"
    ]

  detector :incorrect_length_validation,
    ignore_models: [
      "ActiveStorage::Attachment",
      "ActiveStorage::Blob",
      "ActiveStorage::VariantRecord",
      "ReplyingComment"
    ],
    ignore_attributes: [
      "User.password_digest",
      "Vote.reason"
    ]
end
