# typed: false

require "rails_helper"

RSpec.feature "Color scheme selection" do
  scenario "logged out" do
    visit "/"
    expect(root_classes).to include("color-scheme-system")
  end

  context "logged in" do
    before(:each) { stub_login_as user }

    let(:user) { create(:user, prefers_color_scheme: preferred) }

    context "with no preference set" do
      let(:preferred) { :system }

      it "uses the system colors" do
        expect(root_classes).to include("color-scheme-system")
      end
    end

    context "with preference set to light" do
      let(:preferred) { :light }

      it "uses the system colors" do
        expect(root_classes).to include("color-scheme-light")
      end
    end

    context "with preference set to dark" do
      let(:preferred) { :dark }

      it "uses the system colors" do
        expect(root_classes).to include("color-scheme-dark")
      end
    end
  end

  def root_classes
    page.find("html")["class"].split(" ")
  end
end
