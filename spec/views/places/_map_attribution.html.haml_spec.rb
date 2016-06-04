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

describe "places/_map_attribution.html.haml", type: :view do
  before(:each) do
    render
  end

  it "links to OpenStreetMap" do
    assert_select "a", href: "http://openstreetmap.org",
      text: "OpenStreetMap"
  end

  it "links to the ODbL" do
    assert_select "a", href: "http://www.openstreetmap.org/copyright",
      text: "ODbL"
  end

  it "links to CloudMade" do
    assert_select "a", href: "http://cloudmade.com", text: "CloudMade"
  end
end
