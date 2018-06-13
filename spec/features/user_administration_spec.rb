require 'rails_helper'

RSpec.feature "User Administration" do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  let(:banned) { create(:user, :banned, banner: admin) }
  let(:noinvite) { create(:user, :noinvite, disabler: admin) }

  before(:each) { stub_login_as admin }

  scenario 'diabling invites' do
    expect(user.can_invite?).to be(true)
    visit user_path(user)
    expect(page).to have_button('Disable Invites')
    fill_in 'Reason', with: 'Invited spammers'
    click_on 'Disable Invites'
    expect(page).to have_content('invite capability disabled')
    user.reload
    expect(user.can_invite?).to be(false)
    expect(user.banned_from_inviting?).to be(true)
    expect(user.disabled_invite_reason).to eq('Invited spammers')
    expect(Moderation.order('id asc').last.reason).to eq('Invited spammers')
  end

  scenario 'enabling invites' do
    expect(noinvite.can_invite?).to be(false)
    visit user_path(noinvite)
    click_on 'Enable Invites'
    expect(page).to have_content('invite capability enabled')
    noinvite.reload
    expect(noinvite.can_invite?).to be(true)
    expect(noinvite.banned_from_inviting?).to be(false)
    expect(noinvite.disabled_invite_reason).to be_blank
    expect(Moderation.order('id asc').last.action).to eq('Enabled invitations')
  end

  scenario 'banning' do
    expect(user.is_banned?).to be(false)
    visit user_path(user)
    expect(page).to have_button('Ban')
    fill_in 'Reason', with: 'Spammer'
    click_on 'Ban'
    expect(page).to have_content('banned')
    user.reload
    expect(user.is_banned?).to be(true)
    expect(user.banned_reason).to eq('Spammer')
    expect(Moderation.order('id asc').last.reason).to eq('Spammer')
  end

  scenario "unbanning" do
    expect(banned.is_banned?).to be(true)
    visit user_path(banned)
    click_on 'Unban'
    expect(page).to have_content('unbanned')
    banned.reload
    expect(banned.is_banned?).to be(false)
    expect(banned.banned_reason).to be_blank
    expect(Moderation.order('id asc').last.action).to eq('Unbanned')
  end
end
