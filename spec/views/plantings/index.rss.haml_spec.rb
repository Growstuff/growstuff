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

describe 'plantings/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
  end

  context 'all plantings' do
    before :each do
      @planting = FactoryGirl.create(:planting)
      @sunny = FactoryGirl.create(:sunny_planting)
      @seedling = FactoryGirl.create(:seedling_planting)
      assign(:plantings, [@planting, @sunny, @seedling])
      render
    end

    it 'shows RSS feed title' do
      rendered.should have_content "Recent plantings from all members"
    end

    it 'item title shows owner and location' do
      rendered.should have_content "#{@planting.crop} in #{@planting.location}"
    end

    it 'shows formatted content of posts' do
      rendered.should have_content "This is a <em>really</em> good plant."
    end

    it 'shows sunniness' do
      rendered.should have_content 'Sunniness: sun'
    end

    it 'shows propagation method' do
      rendered.should have_content 'Planted from: seedling'
    end
  end

  context "one person's plantings" do
    before :each do
      @planting = FactoryGirl.create(:planting)
      assign(:plantings, [@planting ])
      assign(:owner, @planting.owner)
      render
    end

    it 'shows title for single member' do
      rendered.should have_content "Recent plantings from #{@planting.owner}"
    end
  end
end
