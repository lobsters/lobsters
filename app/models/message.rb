# typed: false

class Message < ApplicationRecord
  belongs_to :recipient,
    class_name: "User",
    foreign_key: "recipient_user_id",
    inverse_of: :received_messages
  belongs_to :author,
    class_name: "User",
    foreign_key: "author_user_id",
    inverse_of: :sent_messages,
    optional: true
  belongs_to :hat,
    optional: true
  has_one :notification,
    as: :notifiable,
    dependent: :destroy

  include Token

  attribute :mod_note, :boolean
  attr_reader :recipient_username

  validates :subject, length: {in: 1..100}
  validates :body, length: {maximum: 70_000}, on: :update # for weird old data
  validates :body, length: {within: 5..8_192}, on: :create # max from 2024-10-28 on, min changed 2026-01-12
  validates :short_id, presence: true, uniqueness: {case_sensitive: false}, length: {maximum: 30}
  validates :deleted_by_author, :deleted_by_recipient, inclusion: {in: [true, false]}
  validate :hat do
    next if hat.blank?
    if author.blank? || author.wearable_hats.exclude?(hat)
      errors.add(:hat, "not wearable by author")
    end
  end

  scope :inbox, ->(user) {
    where(
      recipient: user,
      deleted_by_recipient: false
    ).preload(:author, :hat, :notification, :recipient).order(id: :asc)
  }
  scope :outbox, ->(user) {
    where(
      author: user,
      deleted_by_author: false
    ).preload(:author, :hat, :notification, :recipient).order(id: :asc)
  }

  before_validation :assign_short_id, on: :create
  after_save :check_for_both_deleted

  def as_json(_options = {})
    attrs = [
      :short_id,
      :created_at,
      :subject,
      :body,
      :deleted_by_author,
      :deleted_by_recipient
    ]

    h = super(only: attrs)

    h[:author_username] = author.try(:username)
    h[:recipient_username] = recipient.try(:username)

    h
  end

  def assign_short_id
    self.short_id = ShortId.new(self.class).generate
  end

  def author_username
    if author
      author.username
    else
      "System"
    end
  end

  def check_for_both_deleted
    if deleted_by_author? && deleted_by_recipient?
      destroy!
    end
  end

  def recipient_username=(username)
    self.recipient_user_id = nil

    if (u = User.find_by(username: username))
      self.recipient_user_id = u.id
      @recipient_username = username
    else
      errors.add(:recipient_username, "is not a valid user")
    end
  end

  def linkified_body
    Markdowner.to_html(body, as_of: created_at)
  end

  def plaintext_body
    # TODO: linkify then strip tags and convert entities back
    body.to_s
  end

  def to_param
    short_id
  end
end
