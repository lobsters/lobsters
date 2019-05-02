require "rails_helper"

describe KeybaseProofsController do
  render_views

  let(:user) { create(:user) }
  let(:kb_username) { "cryptojim" }
  let(:kb_sig) { "1"*66 }
  let(:valid_kb_params) do
    {kb_username: kb_username, kb_signature: kb_sig, kb_ua: "sega-genesis", username: user.username}
  end
  let(:new_params) { valid_kb_params }
  let(:create_params) { {keybase_proof: valid_kb_params} }

  before do
    stub_login_as user
  end

  context 'new' do
    it 'renders the expected kb_username' do
      get :new, params: new_params
      expect(response.body).to include(kb_username)
    end
  end

  context 'create' do
    it 'saves the signature to the user settings' do
      expect(Keybase).to receive(:validate_initial).
        with(kb_username, kb_sig, user.username).and_return(true)

      post :create, params: create_params

      expect(user.reload.keybase_signatures).to eq [{"kb_username" => kb_username, "sig_hash" => kb_sig}]
    end
  end
end
