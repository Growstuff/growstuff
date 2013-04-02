require 'spec_helper'

describe "plantings/show" do
  def create_planting_for(member)
    @garden = FactoryGirl.create(:garden, :owner => @member)
    @crop = FactoryGirl.create(:tomato)
    @planting = assign(:planting,
      FactoryGirl.create(:planting, :garden => @garden, :crop => @crop)
    )
  end

  it "shows the sunniness" do
    controller.stub(:current_user) { nil }
    @member = FactoryGirl.create(:member)
    create_planting_for(@member)
    render
    rendered.should contain 'Sun or shade?'
    rendered.should contain 'sun'
  end

  it "doesn't show sunniness if blank" do
    controller.stub(:current_user) { nil }
    @member = FactoryGirl.create(:member)
    @p = create_planting_for(@member)
    @p.sunniness = ''
    @p.save
    render
    rendered.should_not contain 'Sun or shade?'
    rendered.should_not contain 'sun'
  end

  context "no location set" do
    before(:each) do
      controller.stub(:current_user) { nil }
      @member = FactoryGirl.create(:member)
      create_planting_for(@member)
      render
    end

    it "renders the quantity planted" do
      rendered.should match(/3/)
    end

    it "renders the description" do
      rendered.should match(/This is a/)
    end

    it "renders markdown in the description" do
      assert_select "em", "really"
    end

    it "doesn't contain a () if no location is set" do
      rendered.should_not contain "()"
    end
  end

  context "location set" do
    before(:each) do
      controller.stub(:current_user) { nil }
      @member = FactoryGirl.create(:geolocated_member)
      create_planting_for(@member)
      render
    end

    it "shows the member's location in parentheses" do
      rendered.should contain "(#{@member.location})"
    end
  end
end
