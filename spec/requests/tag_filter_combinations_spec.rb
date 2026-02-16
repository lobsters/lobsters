# typed: false

require "rails_helper"

RSpec.describe "TagFilterCombinations", type: :request do
  let(:user) { create(:user) }
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }
  let(:tag3) { create(:tag) }

  describe "GET /tag_filter_combinations" do
    it "requires login" do
      get tag_filter_combinations_path
      expect(response).to redirect_to(login_path)
    end

    it "shows the index page when logged in" do
      sign_in user
      get tag_filter_combinations_path
      expect(response).to have_http_status(:success)
    end

    it "displays existing combinations" do
      sign_in user
      combo = user.tag_filter_combinations.create!(tags: [tag1, tag2])
      get tag_filter_combinations_path
      expect(response.body).to include(tag1.tag)
      expect(response.body).to include(tag2.tag)
    end
  end

  describe "POST /tag_filter_combinations" do
    it "requires login" do
      post tag_filter_combinations_path, params: {tag_ids: [tag1.id, tag2.id]}
      expect(response).to redirect_to(login_path)
    end

    it "creates a new combination with valid params" do
      sign_in user
      expect {
        post tag_filter_combinations_path, params: {tag_ids: [tag1.id, tag2.id]}
      }.to change { user.tag_filter_combinations.count }.by(1)

      combo = user.tag_filter_combinations.last
      expect(combo.tags).to contain_exactly(tag1, tag2)
      expect(response).to redirect_to(tag_filter_combinations_path)
      expect(flash[:success]).to be_present
    end

    it "rejects combinations with less than 2 tags" do
      sign_in user
      expect {
        post tag_filter_combinations_path, params: {tag_ids: [tag1.id]}
      }.not_to change { user.tag_filter_combinations.count }

      expect(response).to redirect_to(tag_filter_combinations_path)
      expect(flash[:error]).to include("at least 2 tags")
    end

    it "rejects when user already has 15 combinations" do
      sign_in user
      # Create 15 combinations
      15.times do |i|
        tags = [create(:tag), create(:tag)]
        user.tag_filter_combinations.create!(tags: tags)
      end

      expect {
        post tag_filter_combinations_path, params: {tag_ids: [tag1.id, tag2.id]}
      }.not_to change { user.tag_filter_combinations.count }

      expect(response).to redirect_to(tag_filter_combinations_path)
      expect(flash[:error]).to include("more than 15 tag filter combinations")
    end

    it "removes duplicate tag_ids" do
      sign_in user
      post tag_filter_combinations_path, params: {tag_ids: [tag1.id, tag1.id, tag2.id]}

      combo = user.tag_filter_combinations.last
      expect(combo.tags.count).to eq(2)
      expect(combo.tags).to contain_exactly(tag1, tag2)
    end
  end

  describe "DELETE /tag_filter_combinations/:id" do
    let!(:combination) { user.tag_filter_combinations.create!(tags: [tag1, tag2]) }

    it "requires login" do
      delete tag_filter_combination_path(combination)
      expect(response).to redirect_to(login_path)
    end

    it "deletes the combination" do
      sign_in user
      expect {
        delete tag_filter_combination_path(combination)
      }.to change { user.tag_filter_combinations.count }.by(-1)

      expect(response).to redirect_to(tag_filter_combinations_path)
      expect(flash[:success]).to be_present
    end

    it "prevents deleting another user's combination" do
      other_user = create(:user)
      other_combo = other_user.tag_filter_combinations.create!(tags: [tag1, tag2])

      sign_in user
      expect {
        delete tag_filter_combination_path(other_combo)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
