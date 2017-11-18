require 'rails_helper'

describe "plantings/new" do
  before(:each) do
    @member = FactoryBot.create(:member)
    controller.stub(:current_user) { @member }

    # create gardens and crops to populate dropdowns
    @garden_a = FactoryBot.create(:garden, owner: @member)
    @garden_z = FactoryBot.create(:garden, owner: @member)
    @crop1 = FactoryBot.create(:tomato)
    @crop2 = FactoryBot.create(:maize)

    assign(:planting, FactoryBot.create(:planting,
      garden: @garden_a,
      crop: @crop2,
      owner: @member))
  end

  context "logged in" do
    before(:each) do
      sign_in @member
      assign(:planting, Planting.new)
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
