require 'spec_helper'

feature "regular email" do
  before :each do
    @member = FactoryGirl.create(:member)
    visit root_path
    click_link 'Sign in'
    page.should have_content "Sign in"
    fill_in 'Login', :with => @member.login_name
    fill_in 'Password', :with => @member.password
    click_button 'Sign in'
  end

  scenario "sends email" do
    expect {
      # stub for while we're working on this. remove!
      visit send_email_path
    }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
