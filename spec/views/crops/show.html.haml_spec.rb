require 'spec_helper'

describe "crops/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @crop = FactoryGirl.create(:maize,
      :scientific_names => [ FactoryGirl.create(:zea_mays) ]
    )
    @owner    = FactoryGirl.create(:member)
    @garden   = FactoryGirl.create(:garden, :owner => @owner)
    @planting = FactoryGirl.create(:planting,
      :garden => @garden,
      :crop => @crop
    )

    assign(:crop, @crop)

  end

  it "shows the wikipedia URL" do
    render
    assert_select("a[href=#{@crop.en_wikipedia_url}]", 'Wikipedia (English)')
  end

  it "shows the scientific name" do
    render
    rendered.should contain "Scientific names"
    rendered.should contain "Zea mays"
  end

  it "shows a plant this button" do
    render
    rendered.should contain "Plant this"
  end

  it "links to the right crop in the planting link" do
    render
    assert_select("a[href=#{new_planting_path}?crop_id=#{@crop.id}]")
  end

  it "links to people who are growing this crop" do
    render
    rendered.should contain /member\d+/
    rendered.should contain "Springfield Community Garden"
  end

  context "logged in and crop wrangler" do

    before(:each) do
      @member = FactoryGirl.create(:crop_wrangling_member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it "links to the edit crop form" do
      assert_select "a[href=#{edit_crop_path(@crop)}]", :text => "Edit crop"
    end

    it "links to the add scientific name form" do
      assert_select "a[href^=#{new_scientific_name_path}]", :text => "Add"
    end

    it "links to the edit scientific name form" do
      assert_select "a[href=#{edit_scientific_name_path(@crop.scientific_names.first)}]", :text => "Edit"
    end
  end

end
