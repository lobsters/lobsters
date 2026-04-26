# frozen_string_literal: true

# Replaces dependent: :destroy with :restrict_with_exception
# for safer referential integrity per issue #1929

module DependentDestroyRestrict
  extend ActiveSupport::Concern

  class RestrictedDeletionError < StandardError; end

  included do
    # Models that previously used dependent: :destroy should use this instead
    # This provides explicit control over what happens when deleting records
    # that have dependent associations
    def self.restrict_dependent_destroy!(associations: [])
      associations.each do |assoc|
        define_method(:"check_#{assoc}_for_destruction!") do
          if send(assoc).exists?
            raise RestrictedDeletionError,
              "Cannot destroy #{self.class.name}##{id}: has associated #{assoc}"
          end
        end
        before_destroy(:"check_#{assoc}_for_destruction!")
      end
    end
  end
end