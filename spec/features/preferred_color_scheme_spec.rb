# typed: false

require "rails_helper"

RSpec.feature "Color scheme selection" do
  scenario "logged out, defer to user's system" do
    visit "/"
    expect(page.body).to match("system.*.css")
    expect(page.body).to_not match("light.*.css")
    expect(page.body).to_not match("dark.*.css")
  end

  context "logged in" do
    before(:each) { stub_login_as user }

    let(:user) { create(:user, prefers_color_scheme: preferred) }

    context "with no preference set, user's system" do
      let(:preferred) { :system }

      it "uses the system colors" do
        expect(page.body).to match("system.*.css")
        expect(page.body).to_not match("light.*.css")
        expect(page.body).to_not match("dark.*.css")
      end
    end

    context "with preference set to light" do
      let(:preferred) { :light }

      it "uses the system colors" do
        expect(page.body).to_not match("system.*.css")
        expect(page.body).to match("light.*.css")
        expect(page.body).to_not match("dark.*.css")
      end
    end

    context "with preference set to dark" do
      let(:preferred) { :dark }

      it "uses the system colors" do
        expect(page.body).to_not match("system.*.css")
        expect(page.body).to_not match("light.*.css")
        expect(page.body).to match("dark.*.css")
      end
    end
  end
end
