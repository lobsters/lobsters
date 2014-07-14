@javascript
Feature: Duplicate URL validation

  Background:
    Given I am logged in

  Scenario: User submits story with URL which already exists
    Given a story with URL "http://example.com/cool-post" exists
    When I am on the new story page
    And I fill in new story URL with "http://example.com/cool-post"
    Then I should see duplicate story error message

  Scenario: User submits story with unique URL
    When I am on the new story page
    And I fill in new story URL with "http://example.com/cool-post"
    Then I should not see duplicate story error message
