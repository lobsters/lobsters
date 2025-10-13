module UsernameAttribute
  extend ActiveSupport::Concern

  BANNED_USERNAMES = ["admin", "administrator", "contact", "fraud", "guest",
    "help", "hostmaster", "lobster", "lobsters", "mailer-daemon", "moderator",
    "moderators", "nobody", "postmaster", "root", "security", "support",
    "sysop", "webmaster", "enable", "new", "signup"].freeze
  VALID_USERNAME = /[A-Za-z0-9][A-Za-z0-9_-]{0,24}/

  included do
    validates :username,
      format: {with: /\A#{VALID_USERNAME}\z/o},
      length: {maximum: 50}
    validate :underscores_and_dashes_in_username

    validates_each :username do |record, attr, value|
      if BANNED_USERNAMES.include?(value.to_s.downcase) || value.starts_with?("tag-")
        record.errors.add(attr, "is not permitted")
      end
    end
  end

  def underscores_and_dashes_in_username
    username_regex = "^" + username.gsub(/_|-/, "[-_]") + "$"
    return unless username_regex.include?("[-_]")

    collisions = self.class.where("username REGEXP ?", username_regex).where.not(id: id)
    errors.add(:username, "is already in use (perhaps swapping _ and -)") if collisions.any?
  end
end
