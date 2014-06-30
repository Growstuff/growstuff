require 'spec_helper'

describe "crops/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @crop = FactoryGirl.create(:maize,
      :scientific_names => [ FactoryGirl.create(:zea_mays) ]
    )
    assign(:crop, @crop)
  end

  context 'photos' do
    before(:each) do
      @planting = FactoryGirl.create(:planting, :crop => @crop)
      @photo1 = FactoryGirl.create(:photo)
      @photo2 = FactoryGirl.create(:photo)
      @photo3 = FactoryGirl.create(:photo)
      @photo4 = FactoryGirl.create(:photo)
      @planting.photos << [@photo1, @photo2, @photo3, @photo4]
      render
    end

    it 'shows 4 photos across the top of the page' do
      assert_select "div.thumbnail>a>img", :count => 4
    end

    it 'links to the photo detail page' do
      assert_select "a[href=#{photo_path(@photo1)}]"
    end

    it 'links to the photo owner' do
      assert_select "a[href=#{member_path(@photo1.owner)}]"
    end
  end

  context "map" do
    it "has a map" do
      render
      assert_select("div#map")
    end

    it "explains what's shown on the map" do
      render
      rendered.should contain "Only plantings by members who have set their locations are shown on this map"
    end

    it "shows a 'set your location' link to people who need to" do
      @nowhere = FactoryGirl.create(:member)
      sign_in @nowhere
      controller.stub(:current_user) { @nowhere }
      render
      rendered.should contain "Set your location"
    end

    it "doesn't show 'set your location' to people who have one" do
      @somewhere = FactoryGirl.create(:london_member)
      sign_in @somewhere
      controller.stub(:current_user) { @somewhere }
      render
      rendered.should_not contain "Set your location"
    end

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

  context "seeds available for trade" do
    before(:each) do
      @owner1 = FactoryGirl.create(:london_member)
      @owner2 = FactoryGirl.create(:member) # no location
      @seed1 = FactoryGirl.create(:tradable_seed, :owner => @owner1, :crop => @crop)
      @seed2 = FactoryGirl.create(:tradable_seed, :owner => @owner2, :crop => @crop)
      render
    end

    it "shows a heading" do
      rendered.should contain "Find seeds"
    end

    it "shows a list of people with seeds to trade" do
      @crop.seeds.each do |seed|
        assert_select "a[href=#{seed_path(seed)}]"
      end
    end
  end

  context "harvests" do
    before(:each) do
      @owner1 = FactoryGirl.create(:london_member)
      @h1 = FactoryGirl.create(:harvest, :owner => @owner1, :crop => @crop)
      @h2 = FactoryGirl.create(:harvest, :owner => @owner1, :crop => @crop)
      render
    end

    it "shows a heading" do
      rendered.should contain "Harvests"
    end

    it "shows a list of people who have harvested this crop" do
      @crop.harvests.each do |harvest|
        assert_select "a[href=#{harvest_path(harvest)}]"
      end
    end
  end

  context "no seeds available for trade" do
    it "shows a heading" do
      render
      rendered.should contain "Find seeds"
    end

    it "suggests you trade seeds" do
      render
      rendered.should contain "There are no seeds available to trade."
    end
  end

  context "has plantings" do
    before(:each) do
      @owner    = FactoryGirl.create(:member)
      @garden   = FactoryGirl.create(:garden, :owner => @owner)
      @planting = FactoryGirl.create(:planting,
        :garden => @garden,
        :crop => @crop
      )
    end

    it "links to people who are growing this crop" do
      render
      rendered.should contain /member\d+/
      rendered.should contain "Springfield Community Garden"
    end

    it "shows photos where available" do
      @photo = FactoryGirl.create(:photo)
      @planting.photos << @photo
      render
      assert_select "img", :src => @photo.thumbnail_url
    end

  end

  context 'varieties' do
    before(:each) do
      @popcorn = FactoryGirl.create(:popcorn, :parent_id => @crop.id)
      @ubercrop = FactoryGirl.create(:crop, :name => 'ubercrop')
      @crop.parent_id = @ubercrop.id
      @crop.save
      render
    end

    it 'shows popcorn as a child variety' do
      rendered.should contain @popcorn.name
    end

    it 'shows parent crop' do
      rendered.should contain @ubercrop.name
    end

  end

  it 'tells you to sign in/sign up' do
    render
    rendered.should contain 'Sign in or sign up to plant'
  end

  context 'logged in' do
    before(:each) do
      @member = FactoryGirl.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it "shows a plant this button" do
      rendered.should contain "Plant this"
    end

    it "shows a harvest this button" do
      rendered.should contain "Harvest this"
    end

    it "links to the right crop in the planting link" do
      assert_select("a[href=#{new_planting_path}?crop_id=#{@crop.id}]")
    end
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
