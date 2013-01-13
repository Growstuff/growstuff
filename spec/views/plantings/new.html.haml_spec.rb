require 'spec_helper'

describe "plantings/new" do
  before(:each) do
    assign(:planting, FactoryGirl.create(:planting))
  end

  context "logged out" do
    it "doesn't show the planting form if logged out" do
      render
      rendered.should contain "Only logged in users can do this"
    end
  end

  context "logged in" do
    before(:each) do
      @user = FactoryGirl.create(:confirmed_user)
      sign_in @user

      # create gardens and crops to populate dropdowns
      @garden1 = FactoryGirl.create(:garden, :user => @user, :name => 'Garden1')
      @garden2 = FactoryGirl.create(:garden, :user => @user, :name => 'Garden2')
      @crop1 = FactoryGirl.create(:tomato)
      @crop2 = FactoryGirl.create(:maize)

      assign(:crop, @crop2)
      assign(:garden, @garden2)

      render
    end

    it "renders new planting form" do
      assert_select "form", :action => plantings_path, :method => "post" do
        assert_select "select#planting_garden_id", :name => "planting[garden_id]"
        assert_select "select#planting_crop_id", :name => "planting[crop_id]"
        assert_select "input#planting_quantity", :name => "planting[quantity]"
        assert_select "textarea#planting_description", :name => "planting[description]"
      end
    end

    it "selects a crop given in a param" do
      assert_select "select#planting_crop_id",
        :html => /option value="#{@crop2.id}" selected="selected"/
    end

    it "selects a garden given in a param" do
      assert_select "select#planting_garden_id",
        :html => /option value="#{@garden2.id}" selected="selected"/
    end
  end
end
