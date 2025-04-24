module Slug
  extend ActiveSupport::Concern

  included do
    after_initialize { self.slug ||= TypeID.new(self.class.to_s.parameterize) }
  end

  def slug=(new)
    raise ArgumentError, "Slug already set, don't alter it" unless slug.nil?
    super
  end
end
