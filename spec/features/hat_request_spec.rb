# typed: false

require "rails_helper"

RSpec.feature "Hat Request" do
  let(:user) { create(:user) }
  let!(:hat_request) { create(:hat_request, user: user) }
  let(:mod) { create(:user, :moderator) }
  let(:reason) { "An example reason" }

  before do
    stub_login_as mod
    visit "/hat_requests"
  end

  scenario "approving hat request" do
    expect(page).to have_selector(:link_or_button, "Approve Hat Request")
    fill_in "hat_request[reason]", with: reason
    click_on "Approve Hat Request"

    hat = Hat.last
    expect(hat&.hat).to eq(hat_request.hat)
    expect(hat&.link).to eq(hat_request.link)
    expect(hat&.user_id).to eq(hat_request.user_id)
    expect(hat&.granted_by_user_id).to eq(mod.id)

    m = Message.last
    expect(m.author_user_id).to be(mod.id)
    expect(m.subject).to eq("Your hat \"#{hat.hat}\" has been approved")
    expect(m.body).to eq(reason)
  end

  scenario "rejecting hat request" do
    expect(page).to have_selector(:link_or_button, "Reject Hat Request")
    fill_in "hat_request[reason]", with: reason
    click_on "Reject Hat Request"

    hat = Hat.last
    expect(hat&.hat).not_to be(hat_request.hat)
    expect(hat&.link).not_to be(hat_request.link)

    m = Message.last

    expect(m.author_user_id).to be(mod.id)
    expect(m.subject).to eq("Your request for hat \"#{hat_request.hat}\" has been rejected")
    expect(m.body).to eq(reason)
  end
end
