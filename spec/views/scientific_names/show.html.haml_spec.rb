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

describe "scientific_names/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @scientific_name = assign(:scientific_name,
      FactoryGirl.create(:zea_mays)
    )
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Zea mays/)
  end

  context 'signed in' do

    before :each do
      @wrangler = FactoryGirl.create(:crop_wrangling_member)
      sign_in @wrangler
      controller.stub(:current_user) { @wrangler }
      render
    end

    it 'should have an edit button' do
      rendered.should have_content 'Edit'
    end
  end
end
