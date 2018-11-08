require "rails_helper"

describe LoginController do
  let(:user) { create(:user, password: 'asdf') }
  let(:banned) { create(:user, :banned, password: 'asdf') }
  let(:deleted) { create(:user, :deleted, password: 'asdf') }
  let(:banned_wiped) { create(:user, :banned, :wiped, password: 'asdf') }
  let(:deleted_wiped) { create(:user, :deleted, :wiped, password: 'asdf') }

  describe "/login" do
    describe "happy path" do
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
    end

    describe "doesn't log in without correct password" do
      it "doesn't log in with wrong password" do
        post :login, params: { email: user.email, password: 'wrong' }
        expect(session[:u]).to be_nil
        expect(flash[:error]).to match(/Invalid/i)
      end

      it "doesn't log in with blank password" do
        post :login, params: { email: user.email, password: '' }
        expect(session[:u]).to be_nil
        expect(flash[:error]).to match(/Invalid/i)
      end

      it "doesn't log in without any password posted" do
        post :login, params: { email: user.email }
        expect(session[:u]).to be_nil
        expect(flash[:error]).to match(/Invalid/i)
      end
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

    describe "wiped accounts" do
      it "doesn't allow login by banned and wiped users" do
        post :login, params: { email: banned_wiped.email, password: 'asdf' }
        expect(session[:u]).to be_nil
        expect(flash[:error]).to match(/wiped/)
      end

      it "doesn't allow login by deleted and wiped users" do
        post :login, params: { email: deleted_wiped.email, password: 'asdf' }
        expect(session[:u]).to be_nil
        expect(flash[:error]).to match(/wiped/)
      end
    end
  end
end
