desc 'Wipe private data if site is changing hands'
task privacy_wipe: :environment do
  fail "Refusing to wipe. Read and edit this task if your site is really changing hands"

  # It'll be really easy for this rarely-used code to slip out-of-sync,
  # you MUST review how users are banned/deleted before you run this.
  # At the least, check User#delete! and LoginController.
  # User.where.not(deleted_at: nil)
  #     .update_all("password_digest = '*', email = concat(username, '@lobsters.example')")

  # wipe all moderator notes:
  # ModNote.delete_all

  # wipe all private messages:
  # Message.delete_all
end
