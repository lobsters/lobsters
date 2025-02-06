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

    let(:user) { create(:user, prefers_color_scheme: color_scheme, prefers_contrast: contrast) }

    context "with no preferences set" do
      let(:color_scheme) { :system }
      let(:contrast) { :system }

      it "uses system color scheme and system contrast" do
        expect(page.body).to match("system-system-.*.css")
        expect(page.body).to_not match("system-normal-.*.css")
        expect(page.body).to_not match("system-high-.*.css")
        expect(page.body).to_not match("light-system-.*.css")
        expect(page.body).to_not match("dark-system-.*.css")
        expect(page.body).to_not match("light-normal-.*.css")
        expect(page.body).to_not match("light-high-.*.css")
        expect(page.body).to_not match("dark-normal-.*.css")
        expect(page.body).to_not match("dark-high-.*.css")
      end
    end

    context "with system color scheme and normal contrast" do
      let(:color_scheme) { :system }
      let(:contrast) { :normal }

      it "uses system color scheme and normal contrast" do
        expect(page.body).to_not match("system-system-.*.css")
        expect(page.body).to match("system-normal-.*.css")
        expect(page.body).to_not match("system-high-.*.css")
        expect(page.body).to_not match("light-system-.*.css")
        expect(page.body).to_not match("dark-system-.*.css")
        expect(page.body).to_not match("light-normal-.*.css")
        expect(page.body).to_not match("light-high-.*.css")
        expect(page.body).to_not match("dark-normal-.*.css")
        expect(page.body).to_not match("dark-high-.*.css")
      end
    end

    context "with system color scheme and high contrast" do
      let(:color_scheme) { :system }
      let(:contrast) { :high }

      it "uses system color scheme and high contrast" do
        expect(page.body).to_not match("system-system-.*.css")
        expect(page.body).to_not match("system-normal-.*.css")
        expect(page.body).to match("system-high-.*.css")
        expect(page.body).to_not match("light-system-.*.css")
        expect(page.body).to_not match("dark-system-.*.css")
        expect(page.body).to_not match("light-normal-.*.css")
        expect(page.body).to_not match("light-high-.*.css")
        expect(page.body).to_not match("dark-normal-.*.css")
        expect(page.body).to_not match("dark-high-.*.css")
      end
    end

    context "with light color scheme and system contrast" do
      let(:color_scheme) { :light }
      let(:contrast) { :system }

      it "uses light color scheme and system contrast" do
        expect(page.body).to_not match("system-system-.*.css")
        expect(page.body).to_not match("system-normal-.*.css")
        expect(page.body).to_not match("system-high-.*.css")
        expect(page.body).to match("light-system-.*.css")
        expect(page.body).to_not match("dark-system-.*.css")
        expect(page.body).to_not match("light-normal-.*.css")
        expect(page.body).to_not match("light-high-.*.css")
        expect(page.body).to_not match("dark-normal-.*.css")
        expect(page.body).to_not match("dark-high-.*.css")
      end
    end

    context "with dark color scheme and system contrast" do
      let(:color_scheme) { :dark }
      let(:contrast) { :system }

      it "uses dark color scheme and system contrast" do
        expect(page.body).to_not match("system-system-.*.css")
        expect(page.body).to_not match("system-normal-.*.css")
        expect(page.body).to_not match("system-high-.*.css")
        expect(page.body).to_not match("light-system-.*.css")
        expect(page.body).to match("dark-system-.*.css")
        expect(page.body).to_not match("light-normal-.*.css")
        expect(page.body).to_not match("light-high-.*.css")
        expect(page.body).to_not match("dark-normal-.*.css")
        expect(page.body).to_not match("dark-high-.*.css")
      end
    end

    context "with light color scheme and normal contrast" do
      let(:color_scheme) { :light }
      let(:contrast) { :normal }

      it "uses light color scheme and normal contrast" do
        expect(page.body).to_not match("system-system-.*.css")
        expect(page.body).to_not match("system-normal-.*.css")
        expect(page.body).to_not match("system-high-.*.css")
        expect(page.body).to_not match("light-system-.*.css")
        expect(page.body).to_not match("dark-system-.*.css")
        expect(page.body).to match("light-normal-.*.css")
        expect(page.body).to_not match("light-high-.*.css")
        expect(page.body).to_not match("dark-normal-.*.css")
        expect(page.body).to_not match("dark-high-.*.css")
      end
    end

    context "with light color scheme and high contrast" do
      let(:color_scheme) { :light }
      let(:contrast) { :high }

      it "uses system color scheme and system contrast" do
        expect(page.body).to_not match("system-system-.*.css")
        expect(page.body).to_not match("system-normal-.*.css")
        expect(page.body).to_not match("system-high-.*.css")
        expect(page.body).to_not match("light-system-.*.css")
        expect(page.body).to_not match("dark-system-.*.css")
        expect(page.body).to_not match("light-normal-.*.css")
        expect(page.body).to match("light-high-.*.css")
        expect(page.body).to_not match("dark-normal-.*.css")
        expect(page.body).to_not match("dark-high-.*.css")
      end
    end

    context "with dark color scheme and normal contrast" do
      let(:color_scheme) { :dark }
      let(:contrast) { :normal }

      it "uses dark color scheme and normal contrast" do
        expect(page.body).to_not match("system-system-.*.css")
        expect(page.body).to_not match("system-normal-.*.css")
        expect(page.body).to_not match("system-high-.*.css")
        expect(page.body).to_not match("light-system-.*.css")
        expect(page.body).to_not match("dark-system-.*.css")
        expect(page.body).to_not match("light-normal-.*.css")
        expect(page.body).to_not match("light-high-.*.css")
        expect(page.body).to match("dark-normal-.*.css")
        expect(page.body).to_not match("dark-high-.*.css")
      end
    end

    context "with dark color scheme and high contrast" do
      let(:color_scheme) { :dark }
      let(:contrast) { :high }

      it "uses dark color scheme and high contrast" do
        expect(page.body).to_not match("system-system-.*.css")
        expect(page.body).to_not match("system-normal-.*.css")
        expect(page.body).to_not match("system-high-.*.css")
        expect(page.body).to_not match("light-system-.*.css")
        expect(page.body).to_not match("dark-system-.*.css")
        expect(page.body).to_not match("light-normal-.*.css")
        expect(page.body).to_not match("light-high-.*.css")
        expect(page.body).to_not match("dark-normal-.*.css")
        expect(page.body).to match("dark-high-.*.css")
      end
    end
  end
end
