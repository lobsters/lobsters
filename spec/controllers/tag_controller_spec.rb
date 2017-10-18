require "spec_helper"

describe TagsController do
  before { allow(controller).to receive(:require_logged_in_admin) }

  context 'create' do
    it 'creates new tags' do
      post :create, params: { tag: { tag: 'my tag' } }
      expect(Tag.find_by(tag: 'my tag')).to be_valid
      expect(response).to redirect_to tags_path
    end

    it 'does not create a new tag when the name is blank' do
      expect { post :create, params: { tag: { tag: '' } } } .not_to change { Tag.count }
      expect(response).to redirect_to new_tag_path
      expect(flash[:error]).to include "Tag can't be blank"
    end
  end

  context 'update' do
    it 'updates tags with valid params' do
      tag = Tag.first
      post :update, params: { id: tag.id, tag: { tag: 'modified_tag' } }
      expect(Tag.find(tag.id).tag).to eq 'modified_tag'
      expect(response).to redirect_to tags_path
    end
    
    it 'does not update tags when the new name is blank' do
      tag = Tag.first
      post :update, params: { id: tag.id, tag: { tag: '' } }
      expect(Tag.find(tag.id).tag).not_to be_blank
      expect(response).to redirect_to edit_tag_path
    end
  end
end
