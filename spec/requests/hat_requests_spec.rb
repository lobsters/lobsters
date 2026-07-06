# typed: false

require "rails_helper"

RSpec.describe "hat requests controller", type: :request do
  it "requires mod" do
    get "/hat_requests"
    expect(response).to be_redirect

    sign_in create(:user)
    get "/hat_requests"
    expect(response).to be_redirect
  end
end
