module RuboCop
  module Cop
    module Style
      # Disallow the safe navigation operator
      #
      # @example
      #   # bad
      #   foo&.bar
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
