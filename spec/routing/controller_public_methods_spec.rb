# typed: false

require "rails_helper"

# https://gist.github.com/fractaledmind/410e519ccd51445cc10c3408b5f24d77

IGNORED_CONTROLLERS = Set[
  "Rails::MailersController"
]

RSpec.describe "Routing" do
  it "has no unrouted actions (public controller methods)", :aggregate_failures do
    actions_by_controller.each do |controller_path, actions|
      controller_name = "#{controller_path.camelize}Controller"
      next if IGNORED_CONTROLLERS.include?(controller_name)

      # Have to use const_get to go from the string in the routing table to the constant because
      # Rails lazily autoloads constants in dev/test.
      # rubocop:disable Sorbet/ConstantsFromStrings
      controller = Object.const_get(controller_name)
      # rubocop:enable Sorbet/ConstantsFromStrings
      public_methods = controller.public_instance_methods(_include_super = false).map(&:to_s)
      unrouted_actions = public_methods - actions

      expect(unrouted_actions).to be_empty,
        "#{controller_name} has unrouted actions (public methods): #{unrouted_actions.map(&:to_sym)}. These should probably be private"
    end
  end

  private

  def actions_by_controller
    {}.tap do |controllers|
      Rails.application.routes.routes.each do |route|
        controller = route.requirements[:controller]
        action = route.requirements[:action]
        next unless controller && action

        (controllers[controller] ||= []) << action
      end
    end
  end
end
