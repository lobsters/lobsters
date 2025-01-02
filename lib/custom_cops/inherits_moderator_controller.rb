# frozen_string_literal: true

require "active_support/core_ext/string" # String.underscore

module CustomCops
  class InheritsModeratorController < RuboCop::Cop::Base
    MOD_DIRECTORY = "app/controllers/mod/"
    MOD_CONTROLLER = "Mod::ModeratorController"
    MSG = "All controllers in the Mod namespace should inherit from #{MOD_CONTROLLER}"

    def on_class(node)
      rel_path = RuboCop::PathUtil.relative_path(filename(node))

      # make sure we're in the right subdirectory
      return unless rel_path.start_with?(MOD_DIRECTORY)

      class_name = node.identifier.const_name
      # We only care about the class if it matches the expected name for the current filename.
      # If the class name and filepath don't match, Zeitwerk should complain.
      return unless rel_path.end_with?(class_name.underscore + ".rb")

      parent_module_name = node.parent_module_name

      full_class_name = case parent_module_name
      when "Object", ""
        class_name
      else
        "#{parent_module_name}::#{class_name}"
      end

      return if full_class_name == MOD_CONTROLLER

      parent_class = node.parent_class&.const_name || ""

      if parent_class == MOD_CONTROLLER ||
          (parent_module_name.split("::").include?("Mod") && "Mod::#{parent_class}" == MOD_CONTROLLER)
        return
      end

      add_offense(node)
    end

    def filename(node)
      node.location.expression.source_buffer.name
    end
  end
end
