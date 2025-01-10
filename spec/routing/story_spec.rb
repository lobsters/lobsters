require "rails_helper"

describe "story routing", type: :routing do
  let(:story) { create(:story) }

  # 2025-01: Redirects for PR #1414 which moved these routes
  it "is temporary" do
    # expect(get("/stories/#{story.short_id}/suggest")).to eq(200)
    expect(Time.zone.today).to be_before(Date.new(2025, 3, 1))
  end
end
