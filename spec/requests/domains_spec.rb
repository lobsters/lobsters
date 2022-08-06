require 'rails_helper'

RSpec.describe "Domains", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
    allow_any_instance_of(DomainsController).to receive(:require_logged_in_admin)
  end

  context 'update' do
    let(:domain) { create(:domain) }

    it 'updates domain with valid params' do
      post "/domains/#{domain.domain}", params: { domain: { domain: 'modified_domain.com' } }
      expect(Domain.find(domain.id).domain).to eq 'modified_domain.com'
      expect(response).to redirect_to edit_domain_path(domain_name: 'modified_domain.com')
    end

    it 'does not update domain when the new name is blank' do
      post "/domains/#{domain.domain}", params: { domain: { domain: '' } }
      expect(Domain.find(domain.id).domain).not_to be_blank
      expect(response).to redirect_to edit_domain_path
    end
  end

  context 'ban' do
    let(:domain) { create(:domain) }

    it 'buns domain with valid params' do
      messg = 'Banned with reason'
      expect_any_instance_of(Domain).to receive(:ban_by_user_for_reason!).once.with(user, messg)

      post "/domains/ban/#{domain.domain}", params: { domain: { banned_reason: messg } }
      expect(response).to redirect_to edit_domain_path
    end

    it 'bans domain when the reason is blank' do
      expect_any_instance_of(Domain).not_to receive(:ban_by_user_for_reason!)
      post "/domains/ban/#{domain.domain}", params: { domain: { domain: '' } }

      expect(response).to redirect_to edit_domain_path
    end
  end
end
