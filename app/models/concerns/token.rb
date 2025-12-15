module Token
  extend ActiveSupport::Concern

  included do
    after_initialize do
      self.token ||= TypeID.new(self.class.to_s.parameterize) if new_record? || attributes.include?(:token)
    end

    validates :token,
      presence: true,
      uniqueness: {case_sensitive: false},
      length: {maximum: 255}
  end

  def token=(new)
    raise ArgumentError, "token already set, don't alter it" unless token.nil?
    super
  end
end
