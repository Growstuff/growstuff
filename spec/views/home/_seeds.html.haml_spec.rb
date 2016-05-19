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

describe 'home/_seeds.html.haml', type: "view" do
  before(:each) do
    @owner = FactoryGirl.create(:london_member)
    @seed = FactoryGirl.create(:tradable_seed, owner: @owner)
    render
  end

  it 'has a heading' do
    assert_select 'h2', 'Seeds available to trade'
  end

  it 'lists seeds' do
    assert_select "table"
    assert_select 'a', href: crop_path(@seed.crop)
    assert_select 'a', href: crop_path(@seed.owner)
    assert_select 'td', @seed.tradable_to
    assert_select 'td', @seed.owner.location
    assert_select 'a', href: seed_path(@seed)
  end
end
