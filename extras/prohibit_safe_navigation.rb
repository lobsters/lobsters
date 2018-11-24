module RuboCop
  module Cop
    module Style
      # The "safe navigation" operator &. makes it easier to work with and
      # propagate nil values. This will disallow the use of the safe navigation
      # operator
      #
      # @example
      #
      #   # bad
      #   foo&.bar
      #   a.foo&.bar
      #
      class DisallowSafeNavigation < Cop
        extend TargetRubyVersion

        MSG = 'Do not use &.'.freeze

        minimum_target_ruby_version 2.3

        def on_csend(node)
          add_offense(node)
        end
      end
    end
  end
end
