# typed: false

require "rails_helper"

describe "inbox", type: :request do
  let(:user) { create(:user, :admin) }

  before do
    sign_in user
  end

  context "GET inbox/all" do
    it "set title html element" do
      get "/inbox/all"
      assert_select("title", "Inbox | Lobsters")
    end
  end

  context "GET inbox/unread" do
    it "set title html element" do
      get "/inbox/unread"
      assert_select("title", "Unread Inbox | Lobsters")
    end
  end
end
