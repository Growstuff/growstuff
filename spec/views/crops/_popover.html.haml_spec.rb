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

describe "crops/_popover" do
  before(:each) do
    @tomato = FactoryGirl.create(:tomato)
    @sn = FactoryGirl.create(:solanum_lycopersicum, crop: @tomato)
    @planting = FactoryGirl.create(:planting, crop: @tomato)
    @tomato.reload # to pick up latest plantings_count
    render partial: 'crops/popover', locals: { crop: @tomato }
  end

  it 'has a scientific name' do
    rendered.should have_content 'Solanum lycopersicum'
  end

  it 'shows count of plantings' do
    rendered.should have_content '1 time'
  end

end
