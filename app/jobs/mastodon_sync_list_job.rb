# This script is mostly correct but not running in production because:
#  1. Mastodon lists aren't public, so there's no value to it maintaining a list:
#     https://github.com/mastodon/mastodon/issues/8208
#  2. It needs more error-handling. in prod it throws errors about linked accounts that have since
#     been deleted, or are on instances that are down (temporarilty or permanently, etc).
#
# I'm going to leave this code alone until #1 is sorted, then think about how to handle errors:
# we could unlink accounts (bad for temp failures), warn in settings (good but have to figure out
# where to save that state), ignore (probably ok, but a waste of resources for perm failures).

class MastodonSyncListJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return unless Mastodon.enabled? && Rails.application.credentials.mastodon.list_id

    # accept all follow requests
    follow_requests = Mastodon.get_follow_requests
    follow_requests.each do |id|
      Mastodon.accept_follow_request(id)
    end

    # reconcile public list with our linked accounts
    acct_to_id = Mastodon.get_list_accounts
    their_users = acct_to_id.keys.to_set
    our_users = Set.new(
      User.active.where("settings LIKE '%mastodon_username:%'")
        .select { |u| u.mastodon_username.present? }
        .map { |u| "#{u.mastodon_username}@#{u.mastodon_instance}" }
    )

    # puts "their_users", their_users
    # puts "our_users", our_users
    to_remove = their_users - our_users
    to_add = our_users - their_users

    # Mastodon requires following a user to add them to a list

    if to_remove.any?
      Mastodon.remove_list_accounts(to_remove.map { |a| acct_to_id[a] })
      to_remove.each do |a|
        Mastodon.unfollow_account(acct_to_id[a])
      end
    end

    if to_add.any?
      add_ids = []
      to_add.each do |a|
        id = Mastodon.get_account_id(a)
        add_ids << id
        Mastodon.follow_account(id)
      end
      Mastodon.add_list_accounts(add_ids)
    end
  end
end
