require 'rails_helper'

RSpec.describe "Domains", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
    allow_any_instance_of(DomainsController).to receive(:require_logged_in_admin)
  end

  context 'update' do
    let(:domain) { create(:domain) }

    it 'bans domain with valid params' do
      messg = 'Banned with reason'
      expect_any_instance_of(Domain).to receive(:ban_by_user_for_reason!).once.with(user, messg)

      post "/domains/#{domain.domain}", params: { domain: { banned_reason: messg } }
      expect(response).to redirect_to edit_domain_path
    end

    it 'bans domain when the reason is blank' do
      expect_any_instance_of(Domain).not_to receive(:ban_by_user_for_reason!)
      post "/domains/#{domain.domain}", params: { domain: { banned_reason: '' } }

      expect(response).to redirect_to edit_domain_path
    end
  end

  context 'unban' do
    let(:domain) { create(:domain) }

    it 'unbans domain with valid params' do
      messg = 'Unbanned with reason'
      expect_any_instance_of(Domain).to receive(:unban_by_user_for_reason!).once.with(user, messg)

      post "/domains/#{domain.domain}/unban", params: { domain: { banned_reason: messg } }
      expect(response).to redirect_to edit_domain_path
    end

    it 'unbans domain when the reason is blank' do
      expect_any_instance_of(Domain).not_to receive(:unban_by_user_for_reason!)
      post "/domains/#{domain.domain}/unban", params: { domain: { banned_reason: '' } }

      expect(response).to redirect_to edit_domain_path
    end
  end
end
