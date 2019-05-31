require "rails_helper"

describe KeybaseProofsController do
  render_views

  let(:user) { create(:user) }
  let(:kb_username) { "cryptojim" }
  let(:kb_sig) { "1"*66 }
  let(:valid_kb_params) do
    { kb_username: kb_username, kb_signature: kb_sig,
      kb_ua: "sega-genesis", username: user.username, }
  end
  let(:new_params) { valid_kb_params }
  let(:create_params) { { keybase_proof: valid_kb_params } }

  before do
    stub_login_as user
  end

  context 'config' do
    it 'parses to valid json' do
      get :kbconfig
      config = JSON.parse(response.body)

      # rubocop:disable Style/FormatStringToken
      expect(config['profile_url']).to eq "http://test.host/u/%{username}"
      # rubocop:enable Style/FormatStringToken
    end
  end

  context 'new' do
    it 'renders the expected kb_username' do
      get :new, params: new_params
      expect(response.body).to include(kb_username)
    end
  end

  context 'create' do
    context 'when the user does not already have a proof' do
      it 'saves the signature to the user settings' do
        expect(Keybase).to receive(:proof_valid?)
          .with(kb_username, kb_sig, user.username).and_return(true)

        post :create, params: create_params

        expect(user.reload.keybase_signatures).to eq [
          { 'kb_username' => kb_username, 'sig_hash' => kb_sig },
        ]
      end
    end

    context 'when the user already has proofs' do
      let(:other_kb_username) { 'somethingelse' }
      let(:other_kb_sig) { '3'*66 }
      let(:expected_keybase_signatures) do
        [
          { 'kb_username' => kb_username, 'sig_hash' => kb_sig },
          { 'kb_username' => other_kb_username, 'sig_hash' => other_kb_sig },
        ]
      end

      before do
        user.add_or_update_keybase_proof(kb_username, '2'*66)
        user.add_or_update_keybase_proof(other_kb_username, other_kb_sig)
        user.save!
      end

      it 'updates the signature for the matching user and retains any others' do
        expect(Keybase).to receive(:proof_valid?)
          .with(kb_username, kb_sig, user.username).and_return(true)

        post :create, params: create_params

        expect(user.reload.keybase_signatures).to match_array expected_keybase_signatures
      end
    end
  end
end
