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

describe "plantings/new" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    controller.stub(:current_user) { @member }

    # create gardens and crops to populate dropdowns
    @garden_a = FactoryGirl.create(:garden, owner: @member)
    @garden_z = FactoryGirl.create(:garden, owner: @member)
    @crop1 = FactoryGirl.create(:tomato)
    @crop2 = FactoryGirl.create(:maize)

    assign(:planting, FactoryGirl.create(:planting,
      garden: @garden_a,
      crop: @crop2
    ))

  end

  context "logged in" do
    before(:each) do
      sign_in @member
      assign(:planting, Planting.new())
      assign(:crop, @crop2)
      assign(:garden, @garden_z)
      render
    end

    it "renders new planting form" do
      assert_select "form", action: plantings_path, method: "post" do
        assert_select "select#planting_garden_id", name: "planting[garden_id]"
        assert_select "input#crop", class: "ui-autocomplete-input"
        assert_select "input#planting_crop_id", name: "planting[crop_id]"
        assert_select "input#planting_quantity", name: "planting[quantity]"
        assert_select "textarea#planting_description", name: "planting[description]"
        assert_select "select#planting_sunniness", name: "planting[sunniness]"
        assert_select "select#planting_planted_from", name: "planting[planted_from]"
      end
    end

    it 'includes helpful links for crops and gardens' do
      assert_select "a", href: new_garden_path, text: "Add a garden."
    end

    it "selects a garden given in a param" do
      assert_select "select#planting_garden_id",
        html: /option selected value="#{@garden_z.id}"/
    end
  end
end
