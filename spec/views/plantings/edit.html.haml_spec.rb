require 'rails_helper'

describe "plantings/edit" do
  before(:each) do
    @member = FactoryBot.create(:member,
      login_name: 'right',
      email: 'right@example.com')

    # creating two crops to make sure that the correct one is selected
    # in the form.
    @tomato = FactoryBot.create(:tomato)
    @maize = FactoryBot.create(:maize)

    # and likewise for gardens
    @garden =  FactoryBot.create(:garden_z, owner: @member)
    @garden2 = FactoryBot.create(:garden_a, owner: @member)

    @planting = assign(:planting,
      FactoryBot.create(:planting, garden: @garden, crop: @tomato, owner: @member))
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
