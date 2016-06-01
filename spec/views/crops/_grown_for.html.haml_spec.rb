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

describe "crops/_grown_for" do
  before(:each) do
    @crop = FactoryGirl.create(:crop)
    @pp = FactoryGirl.create(:plant_part)
    @harvest = FactoryGirl.create(:harvest,
      crop: @crop,
      plant_part: @pp
    )
  end

  it 'shows plant parts' do
    render partial: 'crops/grown_for', locals: { crop: @crop }
    rendered.should have_content @pp.name
    assert_select "a", href: plant_part_path(@pp)
  end
end
