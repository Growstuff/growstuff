require 'spec_helper'

describe Garden do
  before :each do
    @owner  = FactoryGirl.create(:member)
    @garden = FactoryGirl.create(:garden, :owner => @owner)
  end

  it "should have a slug" do
    @garden.garden_slug.should == "member1-springfield-community-garden"
  end

  it "should have a description" do
    @garden.description.should == "This is a **totally** cool garden"
  end

  it "should have an owner" do
    @garden.owner.should be_an_instance_of Member
  end

  context "featured plantings" do
    before :each do
      @tomato = FactoryGirl.create(:tomato)
      @maize  = FactoryGirl.create(:maize)
      @chard  = FactoryGirl.create(:chard)
      @apple  = FactoryGirl.create(:apple)
      @pear   = FactoryGirl.create(:pear)
      @walnut = FactoryGirl.create(:walnut)
    end

    it "should fetch < 4 featured plantings if insufficient exist" do
      @p1 = FactoryGirl.create(:planting, :crop => @tomato, :garden => @garden)
      @p2 = FactoryGirl.create(:planting, :crop => @maize, :garden => @garden)

      @garden.featured_plantings.should eq [@p2, @p1]

    end

    it "should fetch most recent 4 featured plantings" do
      @p1 = FactoryGirl.create(:planting, :crop => @tomato, :garden => @garden)
      @p2 = FactoryGirl.create(:planting, :crop => @maize, :garden => @garden)
      @p3 = FactoryGirl.create(:planting, :crop => @chard, :garden => @garden)
      @p4 = FactoryGirl.create(:planting, :crop => @apple, :garden => @garden)
      @p5 = FactoryGirl.create(:planting, :crop => @walnut, :garden => @garden)

      @garden.featured_plantings.should eq [@p5, @p4, @p3, @p2]
    end

    it "should skip repeated plantings" do
      @p1 = FactoryGirl.create(:planting, :crop => @tomato, :garden => @garden)
      @p2 = FactoryGirl.create(:planting, :crop => @maize, :garden => @garden)
      @p3 = FactoryGirl.create(:planting, :crop => @chard, :garden => @garden)
      @p4 = FactoryGirl.create(:planting, :crop => @apple, :garden => @garden)
      @p5 = FactoryGirl.create(:planting, :crop => @walnut, :garden => @garden)
      @p6 = FactoryGirl.create(:planting, :crop => @apple, :garden => @garden)
      @p7 = FactoryGirl.create(:planting, :crop => @pear, :garden => @garden)

      @garden.featured_plantings.should eq [@p7, @p6, @p5, @p3]
    end
  end

end
