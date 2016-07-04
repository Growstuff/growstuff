## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe "plantings/show" do
  def create_planting_for(member)
    @garden = FactoryGirl.create(:garden, owner: @member)
    @crop = FactoryGirl.create(:tomato)
    @planting = assign(:planting,
      FactoryGirl.create(:planting, garden: @garden, crop: @crop,
        planted_from: 'cutting')
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
      rendered.should have_content 'Sun or shade?'
      rendered.should have_content 'sun'
    end
  end

  context 'planted from' do
    before(:each) do
      @p = assign(:planting, FactoryGirl.create(:cutting_planting))
    end

    it "shows planted_from" do
      render
      rendered.should have_content 'Planted from:'
      rendered.should have_content 'cutting'
    end

    it "doesn't show planted_from if blank" do
      @p.planted_from = ''
      @p.save
      render
      rendered.should_not have_content 'Planted from:'
      rendered.should_not have_content 'cutting'
    end
  end

  it "shows photos" do
    @photo = FactoryGirl.create(:photo, owner: @member)
    @p.photos << @photo
    render
    assert_select "img[src='#{@photo.thumbnail_url}']"
  end

  it "shows a link to add photos" do
    render
    rendered.should have_content "Add photo"
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
      rendered.should_not have_content "()"
    end
  end

  context "location set" do
    before(:each) do
      @p.owner.location = 'Greenwich, UK'
      @p.owner.save
      render
    end

    it "shows the member's location in parentheses" do
      rendered.should have_content "(#{@p.owner.location})"
    end
  end
end
