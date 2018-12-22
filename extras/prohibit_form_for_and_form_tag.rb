require "rails"

unless Rails.env.production?
  module RuboCop
    module Cop
      module Style
        class DisallowFormForandFormTag < Cop
          MSG = 'Use `.form_with` and remove the `.form_tag` and `.form_for`'.freeze

          def_node_matcher :form_for_exists?, <<-PATTERN
            (send _ :form_for ...)
          PATTERN

          def_node_matcher :form_tag_exists?, <<-PATTERN
            (send _ :form_tag ...)
          PATTERN

          def on_send(node)
            return unless form_for_exists?(node) || form_tag_exists?(node)

            add_offense(node)
          end
        end
      end
    end
  end
end
