class ModNote < ApplicationRecord
  belongs_to :moderator,
             :class_name => "User",
             :foreign_key => "moderator_user_id",
             :inverse_of => :moderations
  belongs_to :user

  scope :recent, -> { where('created_at >= ?', 1.week.ago).order('created_at desc') }
  scope :for, ->(user) { includes(:moderator).where('user_id = ?', user).order('created_at desc') }

  validates :moderator, :user, :note, presence: true

  def note=(n)
    self[:note] = n.to_s.strip
    self.markeddown_note = self.generated_markeddown
  end

  def generated_markeddown
    Markdowner.to_html(self.note)
  end

  def self.create_from_message(message, moderator)
    user = moderator.id == message.recipient.id ? message.author : message.recipient
    ModNote.create!(
      moderator: moderator,
      user: user,
      created_at: message.created_at,
      note: <<~NOTE
        *#{message.author.username} #{message.hat ? message.hat.to_txt : ''}-> #{message.recipient.username}*: #{message.subject}

        #{message.body}
      NOTE
    )
  end
end
