require 'spec_helper'

describe "plantings/new" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    controller.stub(:current_user) { @member }

    # create gardens and crops to populate dropdowns
    @garden_a = FactoryGirl.create(:garden, :owner => @member)
    @garden_z = FactoryGirl.create(:garden, :owner => @member)
    @crop1 = FactoryGirl.create(:tomato)
    @crop2 = FactoryGirl.create(:maize)

    assign(:planting, FactoryGirl.create(:planting,
      :garden => @garden_a,
      :crop => @crop2
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
      assert_select "form", :action => plantings_path, :method => "post" do
        assert_select "select#planting_garden_id", :name => "planting[garden_id]"
        assert_select "select#planting_crop_id", :name => "planting[crop_id]"
        assert_select "input#planting_quantity", :name => "planting[quantity]"
        assert_select "textarea#planting_description", :name => "planting[description]"
        assert_select "select#planting_sunniness", :name => "planting[sunniness]"
        assert_select "select#planting_planted_from", :name => "planting[planted_from]"
      end
    end

    it 'includes helpful links for crops and gardens' do
      assert_select "a[href=#{new_garden_path}]", :text => "Add a garden."
      assert_select "a[href=#{Growstuff::Application.config.new_crops_request_link}]", :text => "Request new crops."
    end

    it "selects a crop given in a param" do
      assert_select "select#planting_crop_id",
        :html => /option value="#{@crop2.id}" selected="selected"/
    end

    it "selects a garden given in a param" do
      assert_select "select#planting_garden_id",
        :html => /option value="#{@garden_z.id}" selected="selected"/
    end
  end
end
