require 'spec_helper'

describe "members/show" do

  before(:each) do
    controller.stub(:current_user) { Member.new }
    @member = FactoryGirl.create(:member)
    @time = @member.created_at

    @garden   = FactoryGirl.create(:garden, :owner => @member)
    @planting = FactoryGirl.create(:planting, :garden => @garden)
    render
  end

  it "shows account creation date" do
    rendered.should contain "Member since"
    rendered.should contain @time.strftime("%B %d, %Y")
  end

  it "contains a gravatar icon" do
    assert_select "img", :src => /gravatar\.com\/avatar/
  end

  it "shows the auto-created garden" do
    assert_select "li.active>a", :text => "Garden"
  end

  it 'shows the garden description' do
    rendered.should contain "totally cool garden"
  end

  it 'renders markdown in the garden description' do
    assert_select "strong", "totally"
  end

  it "shows the plantings in the garden" do
    rendered.should contain @planting.crop.system_name
  end

  it "doesn't show the note about random plantings" do
    rendered.should_not contain "Note: these are a random selection"
  end

  context "signed in member" do
    before(:each) do
      sign_in @member
      render
    end

    it "contains a 'New Garden' link" do
      assert_select "a[href=#garden_new]", :text => "New Garden"
    end
  end

end
