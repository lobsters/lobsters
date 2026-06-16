# We have users that are unusually likely to use old, experimental, and even homemade browsers,
# so we try to only use CSS in the "widely available" baseline:
# https://web-platform-dx.github.io/web-features/

require "rails_helper"
require "crass"

DATA_URL = "https://github.com/web-platform-dx/web-features/releases/download/next/data.json"

ALLOWED_AT_RULES = Set.new(%w[])

# user-select https://caniuse.com/user-select-none https://bugs.webkit.org/show_bug.cgi?id=208677
# WebKit is the holdout on unprefixed support. I'm very sensitive about losing the user's work
# writing comments, that is the beating heart of the site.
ALLOWED_PROPERTIES = Set.new(%w[user-select])

ALLOWED_PROPERTY_VALUES = Set.new([])

# :has() https://caniuse.com/css-has
# Unprincipled exception because it solves so many big problems.
ALLOWED_SELECTORS = Set.new(%w[has])

# textarea { field-sizing: content; resize: vertical; } would let us delete autosize.js
WANTED_PROPERTIES = Set.new(%w[field-sizing resize])

WANTED_PROPERTY_VALUES = Set.new([["appearance", "base-select"]])

BaselineAtRule = Data.define(:name)
BaselineProperty = Data.define(:name)
BaselinePropertyValue = Data.define(:name, :value)
BaselineSelector = Data.define(:name)

Violation = Data.define(:line, :kind, :name) do
  def to_s
    "line #{line}: #{kind} '#{name}' is not Baseline widely available"
  end
end

def fetch_feature_data
  # allow this helper to make a real network call to get the CSS availability data
  WebMock.allow_net_connect!
  VCR.turn_off!

  cache_file = Rails.root.join("tmp/web_feature_availibility.json")
  data = if cache_file.exist? && cache_file.mtime.after?(1.week.ago)
    cache_file.read
  else
    response = Sponge.fetch(DATA_URL)
    raise "Failed to download availability data" unless response
    # puts response.inspect
    File.binwrite(cache_file, response.body)
    response.body
  end

  JSON.parse(data)
ensure
  WebMock.disable_net_connect!
  VCR.turn_on!
end

# https://github.com/mdn/browser-compat-data/blob/main/schemas/compat-data-schema.md
# baseline "high" == "widely available"
# {
#   "features" => {
#     "all" => {
#       "status" => {
#         "by_compat_key" => {
#           "css.properties.all" => { "baseline" => "high" },
#           "css.selectors.is"   => { "baseline" => "high" }
#         }
#       }
#     }
#   }
# }
def extract_widely_available(data:)
  baseline = []
  restricted_values = []

  data["features"].each_value { |feature|
    (feature.dig("status", "by_compat_key") || {}).each { |key, status|
      parts = key.split(".")

      next unless parts[0] == "css" && parts.length >= 3

      case parts[1]
      when "at-rules"
        baseline << BaselineAtRule.new(name: parts[2]) if status["baseline"] == "high"
      when "properties"
        if parts.length == 3
          baseline << BaselineProperty.new(name: parts[2]) if status["baseline"] == "high"
        elsif parts.length == 4
          restricted_values << BaselinePropertyValue.new(name: parts[2], value: parts[3]) if status["baseline"] != "high"
        end
      when "selectors"
        baseline << BaselineSelector.new(name: parts[2]) if status["baseline"] == "high"
      end
    }
  }

  [baseline.to_set, restricted_values.to_set]
end

def find_violations(baseline:, restricted_values:, css_file:)
  css = File.read(css_file)
  tree = Crass.parse(css)
  check_nodes(baseline:, restricted_values:, nodes: tree, css:)
end

def check_nodes(baseline:, restricted_values:, nodes:, css:)
  return [] unless nodes

  nodes.flat_map { |node|
    violation = case node[:node]
    when :property then check_property(baseline:, node:, css:) || check_property_value(restricted_values:, node:, css:)
    when :style_rule then check_selector(baseline:, node:, css:)
    when :at_rule then check_at_rule(baseline:, node:, css:)
    end

    [
      *violation,
      *check_nodes(baseline:, restricted_values:, nodes: node[:children], css:),
      *check_nodes(baseline:, restricted_values:, nodes: node[:block], css:)
    ]
  }
end

def token_line(tokens:, css:)
  return "?" unless tokens&.first
  pos = tokens.first[:pos]
  return "?" unless pos
  css[0...pos].count("\n") + 1
end

def check_at_rule(baseline:, node:, css:)
  name = node[:name]
  return if ALLOWED_AT_RULES.include?(name)
  return if baseline.include?(BaselineAtRule.new(name:))

  line = token_line(tokens: node[:tokens], css:)
  Violation.new(kind: :at_rule, line:, name:)
end

def check_property(baseline:, node:, css:)
  name = node[:name]
  return if name.start_with?("--") # ignore variables
  return if name.start_with?("-webkit-")
  return if name.start_with?("-moz-")
  return if name.start_with?("-ms-")
  return if ALLOWED_PROPERTIES.include?(name)
  return if baseline.include?(BaselineProperty.new(name:))

  line = token_line(tokens: node[:tokens], css:)
  Violation.new(kind: :property, line:, name:)
end

def check_property_value(restricted_values:, node:, css:)
  value = node[:value].to_s.strip
  name = node[:name]

  return if ALLOWED_PROPERTY_VALUES.include?([name, value])
  return unless restricted_values.include?(BaselinePropertyValue.new(name: name, value:))

  line = token_line(tokens: node[:tokens], css:)
  Violation.new(kind: :property_value, line:, name: "#{name}: #{value}")
end

def check_selector(baseline:, node:, css:)
  node.dig(:selector, :value).scan(/::?([\w-]+)/).filter_map { |match|
    name = match[0]
    next if name.start_with?("-webkit-")
    next if name.start_with?("-moz-")
    next if name.start_with?("-ms-")
    next if ALLOWED_SELECTORS.include?(name)
    next if baseline.include?(BaselineSelector.new(name:))

    line = token_line(tokens: node.dig(:selector, :tokens), css:)
    Violation.new(kind: :selector, line:, name:)
  }
end

RSpec.describe "CSS" do
  css_files = Dir.glob("app/assets/stylesheets/**/*.css").sort
  baseline, restricted_values = extract_widely_available(data: fetch_feature_data)

  css_files.each do |css_file|
    it "#{css_file} uses only Baseline widely available features" do
      violations = find_violations(baseline:, restricted_values:, css_file:)
      expect(violations).to be_empty,
        "CSS features not Baseline widely available:\n  #{violations.join("\n  ")}\n" \
          "See: https://web-platform-dx.github.io/web-features/"
    end
  end

  ALLOWED_AT_RULES.each do |at_rule|
    it "exception '#{at_rule}' is still not Baseline widely available" do
      expect(baseline).not_to include(BaselineAtRule.new(name: at_rule)),
        "At rule '#{at_rule}' is now Baseline widely available! " \
          "Remove it from ALLOWED_AT_RULES in #{__FILE__} and rejoice."
    end
  end

  ALLOWED_PROPERTIES.each do |prop|
    it "exception '#{prop}' is still not Baseline widely available" do
      expect(baseline).not_to include(BaselineProperty.new(name: prop)),
        "Property '#{prop}' is now Baseline widely available! " \
          "Remove it from ALLOWED_PROPERTIES in #{__FILE__} and rejoice."
    end
  end

  ALLOWED_SELECTORS.each do |sel|
    it "exception ':#{sel}' is still not Baseline widely available" do
      expect(baseline).not_to include(BaselineSelector.new(name: sel)),
        "Selector ':#{sel}' is now Baseline widely available! " \
          "Remove it from ALLOWED_SELECTORS in #{__FILE__} and rejoice."
    end
  end

  # lazy, not doing WANTED_AT_RULES and WANTED_SELECTORS until we want some

  WANTED_PROPERTIES.each do |prop|
    it "wanted property '#{prop}' is not yet Baseline widely available" do
      expect(baseline).not_to include(BaselineProperty.new(name: prop)),
        "Property '#{prop}' is now Baseline widely available! " \
          "See comment in this spec for where we wanted to use it."
    end
  end

  WANTED_PROPERTY_VALUES.each do |prop_val|
    it "wanted property_value '#{prop_val[0]}: #{prop_val[1]}' is not yet Baseline widely available" do
      expect(restricted_values).to include(BaselinePropertyValue.new(property: prop_val[0], value: prop_val[1])),
        "Property Value '#{prop_val[0]}: #{prop_val[1]}' is now Baseline widely available! " \
          "See comment in this spec for where we wanted to use it."
    end
  end
end
