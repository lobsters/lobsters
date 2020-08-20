require 'rails_helper'

describe 'tags', type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
    allow_any_instance_of(TagsController).to receive(:require_logged_in_admin)
  end

  context 'create' do
    it 'creates new tags' do
      post "/tags",
           params: { tag: { category_name: Category.first.category, tag: 'mytag' } }
      expect(response).to redirect_to tags_path
      expect(Tag.find_by(tag: 'mytag')).to be_valid
    end

    it 'does not create a new tag when the name is blank' do
      expect { post "/tags", params: { tag: { tag: '' } } } .not_to(change { Tag.count })
      expect(response).to redirect_to new_tag_path
      expect(flash[:error]).to include "Tag can't be blank"
    end

    it 'creates new tags with expected params' do
      post "/tags", params: { tag: {
        category_name: Category.first.category,
        tag: 'mytag',
        description: 'desc',
        is_media: true,
        hotness_mod: 1.5,
        privileged: true,
        active: false,
      } }
      tag = Tag.find_by(tag: 'mytag')
      expect(tag.description).to eq 'desc'
      expect(tag.is_media).to be true
      expect(tag.hotness_mod).to eq 1.5
      expect(tag.privileged).to be true
      expect(tag.active).to be false
    end

    it 'creates a moderation with the expected tag_id and user_id' do
      post "/tags", params: { tag: { category_name: Category.first.category, tag: 'mytag' } }
      mod = Moderation.order(id: :desc).first
      expect(mod.tag_id).to eq Tag.order(id: :desc).first.id
      expect(mod.moderator_user_id).to eq user.id
    end
  end

  context 'update' do
    let(:tag) { Tag.first }

    it 'updates tags with valid params' do
      post "/tags/#{tag.tag}", params: { tag: { tag: 'modified_tag' } }
      expect(Tag.find(tag.id).tag).to eq 'modified_tag'
      expect(response).to redirect_to tags_path
    end

    it 'does not update tags when the new name is blank' do
      post "/tags/#{tag.tag}", params: { tag: { tag: '' } }
      expect(Tag.find(tag.id).tag).not_to be_blank
      expect(response).to redirect_to edit_tag_path
    end

    it 'rejects updates with unpermiited params' do
      expect { post "/tags/#{tag.tag}", params: { tag: { is_media: true } } }
        .to raise_error ActionController::UnpermittedParameters
    end

    it 'updates with all permitted params' do
      post "/tags/#{tag.tag}", params: { tag: {
        tag: 'mytag',
        description: 'desc',
        hotness_mod: 1.5,
        privileged: true,
        active: true,
      } }
      new_tag = Tag.find(tag.id)
      expect(new_tag.tag).to eq 'mytag'
      expect(new_tag.description).to eq 'desc'
      expect(new_tag.hotness_mod).to eq 1.5
      expect(new_tag.privileged).to be true
      expect(new_tag.active).to be true
    end

    it 'creates a moderation with the expected user_id' do
      post "/tags/#{tag.tag}", params: { tag: { tag: 'modified_tag' } }
      expect(Moderation.order(id: :desc).first.moderator_user_id).to eq user.id
    end
  end
end
