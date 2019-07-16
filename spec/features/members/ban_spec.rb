require 'rails_helper'

describe "members list" do
  let!(:spammer) { FactoryBot.create :member }
  let!(:admin) { FactoryBot.create :admin_member }

  context 'logged in  as admin' do
    before do
      login_as admin
      visit member_path(spammer)
    end
    it { expect(page).to have_link "Ban member" }
    describe 'bans the user' do
      before do
        accept_confirm { click_link 'Ban member' }
      end
      it { expect(page).to have_link admin.login_name }
      it { expect(page).not_to have_link spammer.login_name }
    end
  end
end
