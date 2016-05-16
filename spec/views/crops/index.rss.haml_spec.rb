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

describe 'crops/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
    @author = FactoryGirl.create(:member)
    @tomato = FactoryGirl.create(:tomato)
    @maize = FactoryGirl.create(:maize)
    assign(:crops, [@tomato, @maize])
    render
  end

  it 'shows RSS feed title' do
    rendered.should have_content "Recently added crops"
  end

  it 'shows names of crops' do
    rendered.should have_content @tomato.name
    rendered.should have_content @maize.name
  end

end
