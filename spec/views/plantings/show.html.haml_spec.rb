require 'spec_helper'

describe "plantings/show" do
  def create_planting_for(member)
    @garden = FactoryGirl.create(:garden, :owner => @member)
    @crop = FactoryGirl.create(:tomato)
    @planting = assign(:planting,
      FactoryGirl.create(:planting, :garden => @garden, :crop => @crop,
        :planted_from => 'cutting')
    )
  end

  before (:each) do
    @member = FactoryGirl.create(:member)
    controller.stub(:current_user) { @member }
    @p = create_planting_for(@member)
  end

  context 'sunniness' do
    before(:each) do
      @p = assign(:planting,
        FactoryGirl.create(:sunny_planting)
      )
    end

    it "shows the sunniness" do
      render
      rendered.should contain 'Sun or shade?'
      rendered.should contain 'sun'
    end

    it "doesn't show sunniness if blank" do
      @p.sunniness = ''
      @p.save
      render
      rendered.should_not contain 'Sun or shade?'
      rendered.should_not contain 'sun'
    end
  end

  context 'planted from' do
    before(:each) do
      @p = assign(:planting, FactoryGirl.create(:cutting_planting))
    end

    it "shows planted_from" do
      render
      rendered.should contain 'Planted from:'
      rendered.should contain 'cutting'
    end

    it "doesn't show planted_from if blank" do
      @p.planted_from = ''
      @p.save
      render
      rendered.should_not contain 'Planted from:'
      rendered.should_not contain 'cutting'
    end
  end

  it "shows photos" do
    @photo = FactoryGirl.create(:photo, :owner => @member)
    @p.photos << @photo
    render
    assert_select "img[src=#{@photo.thumbnail_url}]"
  end

  it "shows a link to add photos" do
    render
    rendered.should contain "Add photo"
  end

  context "no location set" do
    before(:each) do
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
      @member.location = 'Greenwich, UK'
      @member.save
      render
    end

    it "shows the member's location in parentheses" do
      rendered.should contain "(#{@member.location})"
    end
  end
end
