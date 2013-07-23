require 'spec_helper'

describe "crops/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @crop = FactoryGirl.create(:maize,
      :scientific_names => [ FactoryGirl.create(:zea_mays) ]
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

  it "shows a list of people with seeds to trade when seeds are available for trade" do
    @owner = FactoryGirl.create(:london_member)
    @owner2 = FactoryGirl.create(:london_member)
    @seed1 = FactoryGirl.build(:tradable_seed, :owner => @owner)
    @seed2 = FactoryGirl.build(:tradable_seed, :owner => @owner2)
    @crop.seeds = [@seed1, @seed2]
    render
    rendered.should contain "Seeds available for trade:"
    @crop.seeds.each do |seed|
      assert_select "a[href=#{seed_path(seed)}]"
    end
  end

  it "does not show a list of people with seeds to trade if there are none" do
    render
    rendered.should_not contain "Seeds available for trade:"
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

    it "doesn't show sunniness if none are set" do
      render
      rendered.should_not contain "Plant in:"
    end

    it "shows sunniness frequencies" do
      FactoryGirl.create(:sunny_planting, :crop => @crop)
      render
      rendered.should contain "Plant in:"
      rendered.should contain "sun (1)"
    end

    it "shows multiple sunniness frequencies" do
      FactoryGirl.create(:sunny_planting, :crop => @crop)
      FactoryGirl.create(:sunny_planting, :crop => @crop)
      FactoryGirl.create(:shady_planting, :crop => @crop)
      render
      rendered.should contain "Plant in:"
      rendered.should contain "sun (2), shade (1)"
    end

    it "doesn't show planted_from if none are set" do
      render
      rendered.should_not contain "Plant from:"
    end

    it "shows planted_from frequencies" do
      FactoryGirl.create(:seed_planting, :crop => @crop)
      render
      rendered.should contain "Plant from:"
      rendered.should contain "seed (1)"
    end

    it "shows multiple planted_from frequencies" do
      FactoryGirl.create(:seed_planting, :crop => @crop)
      FactoryGirl.create(:seed_planting, :crop => @crop)
      FactoryGirl.create(:cutting_planting, :crop => @crop)
      render
      rendered.should contain "Plant from:"
      rendered.should contain "seed (2), cutting (1)"
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
      @ubercrop = FactoryGirl.create(:crop, :system_name => 'ubercrop')
      @crop.parent_id = @ubercrop.id
      @crop.save
      render
    end

    it 'shows popcorn as a child variety' do
      rendered.should contain @popcorn.system_name
    end

    it 'shows parent crop' do
      rendered.should contain @ubercrop.system_name
    end

  end

  it 'tells you to sign in/sign up' do
    render
    rendered.should contain 'Sign in or sign up to plant'
    rendered.should contain 'Sign in or sign up to add seed'
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
