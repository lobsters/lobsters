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

  describe "/login/reset_password" do
    it "starts reset process" do
      expect {
        post :reset_password, params: { email: user.email }
        expect(flash[:success]).to_not be_nil
      }.to(change { User.find(user.id).password_reset_token })
    end

    it "starts reset process for deleted users" do
      expect {
        post :reset_password, params: { email: deleted.email }
        expect(flash[:success]).to_not be_nil
      }.to(change { User.find(deleted.id).password_reset_token })
    end

    it "doesn't start reset process if user was banned" do
      expect {
        post :reset_password, params: { email: banned.email }
        expect(flash[:success]).to be_nil
      }.not_to(change { User.find(banned.id).password_reset_token })
    end

    it "doesn't start reset process if user was deleted and wiped" do
      expect {
        post :reset_password, params: { email: deleted_wiped.email }
        expect(flash[:success]).to be_nil
      }.not_to(change { User.find(deleted_wiped.id).password_reset_token })
    end
  end

  describe "/login/set_new_password" do
    it "resets if token matches" do
      user.initiate_password_reset_for_ip('127.0.0.1')
      expect {
        post :set_new_password, params: {
          token: user.password_reset_token,
          password: 'new',
          password_confirmation: 'new',
        }
      }.to(change { User.find(user.id).password_digest })
      expect(User.find(user.id).authenticate('new')).to be_truthy
    end

    it "doesn't reset if token is wrong" do
      user.initiate_password_reset_for_ip('127.0.0.1')
      expect {
        post :set_new_password, params: {
          token: 'totes wrong',
          password: 'new',
          password_confirmation: 'new',
        }
      }.not_to(change { User.find(user.id).password_digest })
    end

    it "doesn't reset if token is missing" do
      expect {
        post :set_new_password, params: {
          password: 'new',
          password_confirmation: 'new',
        }
      }.not_to(change { User.find(user.id).password_digest })
    end

    it "doesn't reset if token expired" do
      user.update(password_reset_token: "#{2.days.ago.to_i}-#{Utils.random_str(30)}")
      expect {
        post :set_new_password, params: {
          token: user.password_reset_token,
          password: 'new',
          password_confirmation: 'new',
        }
      }.not_to(change { User.find(user.id).password_digest })
    end

    it "doesn't reset if user is banned" do
      banned.initiate_password_reset_for_ip('127.0.0.1')
      expect {
        post :set_new_password, params: {
          token: banned.password_reset_token,
          password: 'new',
          password_confirmation: 'new',
        }
      }.not_to(change { User.find(banned.id).password_digest })
    end
  end
end
