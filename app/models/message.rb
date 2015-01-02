class Message < ActiveRecord::Base
  belongs_to :recipient,
    :class_name => "User",
    :foreign_key => "recipient_user_id"
  belongs_to :author,
    :class_name => "User",
    :foreign_key => "author_user_id"

  validates_presence_of :recipient
  validates_presence_of :author

  attr_accessor :recipient_username

  validates_length_of :subject, :in => 1..150
  validates_length_of :body, :maximum => (64 * 1024)

  before_validation :assign_short_id,
    :on => :create
  after_create :deliver_email_notifications
  after_save :update_unread_counts
  after_save :check_for_both_deleted

  def assign_short_id
    self.short_id = ShortId.new(self.class).generate
  end

  def check_for_both_deleted
    if self.deleted_by_author? && self.deleted_by_recipient?
      self.destroy
    end
  end

  def update_unread_counts
    self.recipient.update_unread_message_count!
  end

  def deliver_email_notifications
    if self.recipient.email_messages?
      begin
        EmailMessage.notify(self, self.recipient).deliver
      rescue => e
        Rails.logger.error "error e-mailing #{self.recipient.email}: #{e}"
      end
    end

    if self.recipient.pushover_messages?
      self.recipient.pushover!({
        :title => "#{Rails.application.name} message from " <<
          "#{self.author.username}: #{self.subject}",
        :message => self.plaintext_body,
        :url => self.url,
        :url_title => "Reply to #{self.author.username}",
      })
    end
  end

  def recipient_username=(username)
    self.recipient_user_id = nil

    if u = User.where(:username => username).first
      self.recipient_user_id = u.id
      @recipient_username = username
    else
      errors.add(:recipient_username, "is not a valid user")
    end
  end

  def linkified_body
    Markdowner.to_html(self.body)
  end

  def plaintext_body
    # TODO: linkify then strip tags and convert entities back
    self.body.to_s
  end

  def url
    Rails.application.root_url + "messages/#{self.short_id}"
  end
end
