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

describe "seeds/new" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @seed1 = FactoryGirl.create(:seed, owner: @member)
    assign(:seed, @seed1)
  end

  it "renders new seed form" do
    render
    assert_select "form", action: seeds_path, method: "post" do
      assert_select "input#crop", class: "ui-autocomplete-input"
      assert_select "input#seed_crop_id", name: "seed[crop_id]"
      assert_select "textarea#seed_description", name: "seed[description]"
      assert_select "input#seed_quantity", name: "seed[quantity]"
      assert_select "select#seed_tradable_to", name: "seed[tradable_to]"
    end
  end

  it 'reminds you to set your location' do
    render
    rendered.should have_content "Don't forget to set your location."
    assert_select "a", text: "set your location"
  end

  context 'member has location' do
    before(:each) do
      @member = FactoryGirl.create(:london_member)
      sign_in @member
      controller.stub(:current_user) { @member }
      @seed1 = FactoryGirl.create(:seed, owner: @member)
      assign(:seed, @seed1)
    end

    it 'shows the location' do
      render
      rendered.should have_content "from #{@member.location}."
      assert_select 'a', href: place_path(@member.location)
    end

    it 'links to change location' do
      render
      assert_select "a", text: "Change your location."
    end
  end

end
