require 'rails_helper'

describe "seeds/new" do
  before(:each) do
    @member = FactoryBot.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @seed1 = FactoryBot.create(:seed, owner: @member)
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
      @member = FactoryBot.create(:london_member)
      sign_in @member
      controller.stub(:current_user) { @member }
      @seed1 = FactoryBot.create(:seed, owner: @member)
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
