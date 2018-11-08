require "rails_helper"

describe LoginController do
  let(:user) { create(:user, password: 'asdf') }
  let(:banned) { create(:user, :banned, password: 'asdf') }
  let(:deleted) { create(:user, :deleted, password: 'asdf') }
  let(:banned_gone) { create(:user, :banned, :gone, password: 'asdf') }
  let(:deleted_gone) { create(:user, :deleted, :gone, password: 'asdf') }

  it "logs in with email and correct password" do
    post :login, params: { email: user.email, password: 'asdf' }
    expect(flash[:error]).to be_nil
    expect(response).to redirect_to('/')
  end

  it "logs in with username and correct password" do
    post :login, params: { email: user.username, password: 'asdf' }
    expect(session[:u]).to eq(user.session_token)
    expect(flash[:error]).to be_nil
    expect(response).to redirect_to('/')
  end

  it "doesn't log in without correct password" do
    post :login, params: { email: user.email, password: 'wrong' }
    expect(session[:u]).to be_nil
    expect(flash[:error]).to match(/Invalid/i)

    post :login, params: { email: user.email, password: '' }
    expect(session[:u]).to be_nil
    expect(flash[:error]).to match(/Invalid/i)

    post :login, params: { email: user.email }
    expect(session[:u]).to be_nil
    expect(flash[:error]).to match(/Invalid/i)
  end

  it "doesn't allow login by banned users" do
    post :login, params: { email: banned.email, password: 'asdf' }
    expect(session[:u]).to be_nil
    expect(flash[:error]).to match(/banned/)
  end

  it "doesn't allow login by deleted users" do
    post :login, params: { email: deleted.email, password: 'asdf' }
    expect(session[:u]).to be_nil
    expect(flash[:error]).to match(/deleted/)
  end
end
