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

describe 'seeds/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
  end

  context 'all seeds' do
    before(:each) do
      @seed = FactoryGirl.create(:seed)
      @tradable = FactoryGirl.create(:tradable_seed)
      assign(:seeds, [ @seed, @tradable ])
      render
    end

    it 'shows RSS feed title' do
      rendered.should have_content "Recent seeds from all members"
    end

    it 'has a useful item title' do
      rendered.should have_content "#{@seed.owner}'s #{@seed.crop} seeds"
    end

    it 'shows the seed count' do
      rendered.should have_content "Quantity: #{@seed.quantity}"
    end

    it 'shows the plant_before date' do
      rendered.should have_content "Plant before: #{@seed.plant_before.to_s}"
    end

    it 'mentions that one seed is tradable' do
      rendered.should have_content "Will trade #{@tradable.tradable_to} from #{@tradable.owner.location}"
    end

  end

  context "one member's seeds" do
    before(:each) do
      @seed = FactoryGirl.create(:seed)
      assign(:seeds, [ @seed ])
      assign(:owner, @seed.owner)
      render
    end

    it 'shows RSS feed title' do
      rendered.should have_content "Recent seeds from #{@seed.owner}"
    end
  end
end
