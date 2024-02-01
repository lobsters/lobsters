# typed: false

require "rails_helper"

describe Category do
  context "validations" do
    it "allows a valid category to be created" do
      category = Category.create!(
        category: Faker::Lorem.word
      )
      expect(category).to be_valid
    end

    it "does not allow a category to be saved without a name" do
      expect(Category.create).not_to be_valid
    end

    it "does not allow an empty category to be saved" do
      expect(Category.create(category: "")).not_to be_valid
    end

    it "does not allow a category with a name too long to be saved" do
      expect(Category.create(category: "A" * 26)).not_to be_valid
    end
  end

  context "logs modification in moderation log" do
    let(:edit_user) { create :user }

    it "logs on create" do
      expect { Category.create(category: "new_category", edit_user_id: edit_user.id) }
        .to change { Moderation.count }.by(1)
      mod = Moderation.last
      expect(mod.action).to include "new_category"
      expect(mod.action).to start_with "Created new category"
      expect(mod.moderator_user_id).to be edit_user.id
    end

    it "logs on update" do
      expect { Category.first.update(category: "new_category_name", edit_user_id: edit_user.id) }
        .to change { Moderation.count }.by(1)
      mod = Moderation.last
      expect(mod.action).to include "new_category_name"
      expect(mod.action).to start_with "Updating"
      expect(mod.moderator_user_id).to be edit_user.id
    end
  end
end
