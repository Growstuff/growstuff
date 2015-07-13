require 'rails_helper'

feature "signout" do
  let(:member){FactoryGirl.create(:member)}
  
  scenario "redirect to previous page after signout" do
    visit crops_path # some random page
    click_link 'Sign in'
    fill_in 'Login', with: member.login_name
    fill_in 'Password', with: member.password
    click_button 'Sign in'
    click_link 'Sign out'
    current_path.should eq crops_path
  end

  scenario "after signout, redirect to signin page if page needs authentication" do
    models = %w[plantings harvests posts photos gardens seeds]
    models.each do |model|
      visit "/#{model}/new"
      current_path.should eq new_member_session_path
      fill_in 'Login', with: member.login_name
      fill_in 'Password', with: member.password
      click_button 'Sign in'
      current_path.should eq "/#{model}/new"
      click_link 'Sign out'
      current_path.should eq new_member_session_path
    end
  end

end
