require 'spec_helper'

describe "crops/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @crop = FactoryGirl.create(:maize,
      :scientific_names => [ FactoryGirl.create(:zea_mays) ]
    )
    assign(:crop, @crop)
    @author = FactoryGirl.create(:member)
    page = 1
    per_page = 2
    total_entries = 2
    @posts = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
        @post1 = FactoryGirl.create(:post, :author => @author, :body => "Post it!" ),
        @post2 = FactoryGirl.create(:post, :author => @author, :body => "Done!" )
      ])
    end
  end

  context 'photos' do
    before(:each) do
      @planting = FactoryGirl.create(:planting, :crop => @crop)
      @photo1 = FactoryGirl.create(:photo)
      @photo2 = FactoryGirl.create(:photo)
      @photo3 = FactoryGirl.create(:photo)
      @planting.photos << [@photo1, @photo2, @photo3]
      render
    end

    it 'shows 3 photos across the top of the page' do
      assert_select "div.thumbnail>a>img", :count => 3
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
      assert_select("div#cropmap")
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
      @owner    = FactoryGirl.create(:london_member)
      @planting = FactoryGirl.create(:planting,
        :crop => @crop,
        :owner => @owner
      )
      @crop.reload # to pick up latest plantings_count
    end

    it "links to people who are growing this crop" do
      render
      rendered.should contain @owner.login_name
      rendered.should contain @owner.location
    end
  end

  context "has posts" do
    it "links to posts" do
      render
      @posts.each do |p|
        rendered.should contain p.author.login_name
        rendered.should contain p.subject
        rendered.should contain p.body
      end
    end

    it "contains two gravatar icons" do
      render
      assert_select "img", :src => /gravatar\.com\/avatar/, :count => 2
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

  context 'logged in' do
    before(:each) do
      @member = FactoryGirl.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it { rendered.should contain "Nobody has planted this crop yet" }
    it { rendered.should contain "Nobody has harvested this crop yet" }

    context "should have a link to" do
      before do
        FactoryGirl.create(:planting, :crop => @crop)
        FactoryGirl.create(:harvest, :crop => @crop)
        @crop.reload
        render
      end

      it "show all plantings by the crop link" do
        assert_select("a[href=#{plantings_by_crop_path @crop}]")
      end    

      it "show all harvests by the crop link" do
        assert_select("a[href=#{harvests_by_crop_path @crop}]")
      end
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
