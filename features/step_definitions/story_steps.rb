Given(/^a story with URL "(.*?)" exists$/) do |url|
  Story.make! url: url
end

When(/^I am on the new story page$/) do
  visit new_story_path
end

When(/^I fill in new story URL with "(.*?)"$/) do |url|
  fill_in 'URL:', with: url
  page.execute_script("$('#story_url').trigger('change');") # TODO why do we need this?
end

Then(/^I should( not)? see duplicate story error message$/) do |negate|
  expect(page).send(negate ? :not_to : :to, have_text('URL already exist'))
end
