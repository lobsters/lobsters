# typed: false

require "rails_helper"

describe "categories", type: :request do
  let(:user) { create(:user, :admin) }

  before do
    sign_in user
  end

  context "edit" do
    it "set title html element" do
      cat = create :category
      get "/categories/#{cat.category}/edit"
      assert_select("title", "Edit Category #{cat.category} | Lobsters")
    end
  end

  context "list" do
    it "set title html element for single view" do
      cat = create :category
      get "/categories/#{cat.category}"
      assert_select("title", "Category #{cat.category} | Lobsters")
    end

    it "set title html element for multiple view" do
      cat = create :category
      cat2 = create :category
      get "/categories/#{cat.category},#{cat2.category}"
      assert_select("title", "Categories #{cat.category}, #{cat2.category} | Lobsters")
    end
  end
end
