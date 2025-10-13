class Username < ApplicationRecord
  include UsernameAttribute

  belongs_to :user
  validates :created_at, presence: true

  def self.rename!(user:, from:, to:, by:, at: Time.current, reason: nil)
    Username.transaction do
      if by == user
        Moderation.create!({
          is_from_suggestions: true,
          moderator_user_id: nil,
          action: "changed own username from \"#{from}\" to \"#{to}\"",
          reason: reason,
          created_at: at
        })
      else
        Moderation.create!({
          is_from_suggestions: false,
          moderator_user_id: by,
          action: "changed username from \"#{from}\" to \"#{to}\"",
          reason: reason,
          created_at: at
        })
      end

      old_username = Username.where(user_id: id).order(created_at: :desc).limit(1).first
      old_username.renamed_away_at = at
      old_username.save!
      Username.create!({
        username: to,
        user_id: id,
        created_at: at,
        renamed_away_at: nil
      })
    end
  end

  def self.username_regex_s
    "/^" + VALID_USERNAME.to_s.gsub(/(\?-mix:|\(|\))/, "") + "$/"
  end
end
