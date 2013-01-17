require 'spec_helper'

describe "crops/show" do
  before(:each) do
    @crop = assign(:crop, FactoryGirl.create(:maize,
      :scientific_names => [ FactoryGirl.create(:zea_mays) ]
    ))
    @owner    = FactoryGirl.create(:member)
    @garden   = FactoryGirl.create(:garden, :owner => @owner)
    @planting = FactoryGirl.create(:planting,
      :garden => @garden,
      :crop => @crop
    )
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
    rendered.should contain "member1"
  end

  context "logged out" do
    it "doesn't show the edit links if logged out" do
      render
      rendered.should_not contain "Edit"
    end
  end

  context "logged in" do

    before(:each) do
      @member = FactoryGirl.create(:member)
      sign_in @member
      render
    end

    it "links to the edit crop form" do
      rendered.should contain "Edit"
    end
  end

end
