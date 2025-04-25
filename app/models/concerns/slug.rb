module Slug
  extend ActiveSupport::Concern

  included do
    after_initialize do
      self.slug ||= TypeID.new(self.class.to_s.parameterize) if new_record? || attributes.include?(:slug)
    end

    validates :slug, presence: true
  end

  def slug=(new)
    raise ArgumentError, "Slug already set, don't alter it" unless slug.nil?
    super
  end
end
