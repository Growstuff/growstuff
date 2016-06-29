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

describe "plantings/edit" do
  before(:each) do
    @member = FactoryGirl.create(:member,
      login_name: 'right',
      email: 'right@example.com'
    )

    # creating two crops to make sure that the correct one is selected
    # in the form.
    @tomato = FactoryGirl.create(:tomato)
    @maize = FactoryGirl.create(:maize)

    # and likewise for gardens
    @garden =  FactoryGirl.create(:garden_z, owner: @member)
    @garden2 = FactoryGirl.create(:garden_a, owner: @member)

    @planting = assign(:planting,
      FactoryGirl.create(:planting, garden: @garden, crop: @tomato)
    )

  end

  context "logged in" do
    before(:each) do
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it "renders the edit planting form" do
      assert_select "form", action: plantings_path(@planting), method: "post" do
        assert_select "input#planting_quantity", name: "planting[quantity]"
        assert_select "textarea#planting_description", name: "planting[description]"
        assert_select "select#planting_sunniness", name: "planting[sunniness]"
        assert_select "select#planting_planted_from", name: "planting[planted_from]"
      end
    end

    it 'includes helpful links for crops and gardens' do
      assert_select "a[href='#{new_garden_path}']", text: "Add a garden."
    end

    it "chooses the right crop" do
      assert_select "input#crop[value=?]", "tomato"
    end

    it "chooses the right garden" do
      assert_select "select#planting_garden_id",
        html: /option selected value="#{@garden.id}"/
    end

  end
end
