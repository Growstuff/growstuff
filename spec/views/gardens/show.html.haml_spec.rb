require 'spec_helper'

describe "gardens/show" do
  before(:each) do
    @owner    = FactoryGirl.create(:member)
    controller.stub(:current_user) { @owner }
    @garden   = FactoryGirl.create(:garden, :owner => @owner)
    @planting = FactoryGirl.create(:planting, :garden => @garden)
    assign(:garden, @garden)
    render
  end

  it 'should show the description' do
    rendered.should contain "totally cool garden"
  end

  it 'renders markdown in the description' do
    assert_select "strong", "totally"
  end

  it 'should show plantings on the garden page' do
    rendered.should contain @planting.crop.system_name
  end

  it "doesn't show the note about random plantings" do
    rendered.should_not contain "Note: these are a random selection"
  end

  context 'signed in' do

    before :each do
      sign_in @owner
      render
    end

    it 'should have an edit button' do
      rendered.should contain 'Edit'
    end

    it "shows a 'plant something' button" do
      rendered.should contain "Plant something"
    end

    it "links to the right crop in the planting link" do
      assert_select("a[href=#{new_planting_path}?garden_id=#{@garden.id}]")
    end
  end

end
