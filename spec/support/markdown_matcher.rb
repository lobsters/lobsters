module MarkdownMatchers
	extend RSpec::Matchers::DSL
	include Capybara::Node::Matchers

	matcher :parse_emoji do 
		set_default_markdown_messages

		match do |actual|
			expect(actual).to have_selector('h1 a#gitlab-markdown')
			expect(actual).to have_selector('h2 a#markdown')
			expect(actual).to have_selector('h3 a#autolinkfilter')
		end
	end

module RSpec::Matchers::DSL::Macros
	def set_default_markdown_messages
		failure_message do
			# expected to parse emoji, but didn't
			"expected to #{description}, but didn't"
		end
	end
end