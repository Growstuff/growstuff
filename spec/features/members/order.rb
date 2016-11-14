require 'rails_helper'

feature "orders" do

  context "signed in member" do
    let(:member) { FactoryGirl.create(:member) }
    FactoryGirl.create(:product)
    FactoryGirl.create(:account_type)
    FactoryGirl.create(:paid_account_type)
    background do
      login_as(member)
    end

    scenario "makes an order" do
      visit root_path
      click_link "Support Growstuff"
      expect(page).to have_content "please purchase"
    end

  end
end
