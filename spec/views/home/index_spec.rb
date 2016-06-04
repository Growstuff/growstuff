## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe 'home/index.html.haml', type: "view" do
  before(:each) do
    @member = FactoryGirl.create(:london_member)
    @member.updated_at = 2.days.ago
    assign(:interesting_members, [@member])

    @post = FactoryGirl.create(:post, author: @member)
    assign(:posts, [@post])

    @planting = FactoryGirl.create(:planting, owner: @member)
    assign(:plantings, [@planting])

    @crop = FactoryGirl.create(:crop)
    assign(:crops, [@crop])
    assign(:recent_crops, [@crop])
    assign(:seeds, [FactoryGirl.create(:tradable_seed)])
  end

  context 'logged out' do
    before(:each) do
      controller.stub(:current_user) { nil }
      render
    end

    it 'show interesting members' do
      rendered.should have_content @member.login_name
      rendered.should have_content @member.location
    end
  end

  context 'signed in' do
    before(:each) do
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it 'should say welcome' do
      rendered.should have_content "Welcome to #{ENV['GROWSTUFF_SITE_NAME']}, #{@member.login_name}"
    end
  end

end
