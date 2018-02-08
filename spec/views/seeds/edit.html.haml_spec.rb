require 'rails_helper'

describe "seeds/edit" do
  before(:each) do
    @member = FactoryBot.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @seed = FactoryBot.create(:seed, owner: @member)
  end

  it "renders the edit seed form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", action: seeds_path(@seed), method: "post" do
      assert_select "input#crop", class: "ui-autocomplete-input"
      assert_select "input#seed_crop_id", name: "seed[crop_id]"
      assert_select "textarea#seed_description", name: "seed[description]"
      assert_select "input#seed_quantity", name: "seed[quantity]"
      assert_select "select#seed_tradable_to", name: "seed[tradable_to]"
    end
  end

  it "doesn't revert tradable_to to nowhere" do
    @seed = FactoryBot.create(:tradable_seed, owner: @member)
    @seed.tradable_to.should_not eq "nowhere"
    render
    assert_select "option[selected=selected]", text: @seed.tradable_to
  end
end
