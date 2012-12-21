require 'spec_helper'

describe "plantings/show" do
  before(:each) do
    @user = assign(:user, stub_model(User,
      :id => 23,
      :username => 'blah',
      :password => 'blahblah',
      :tos_agreement => true
    ))
    @garden = assign(:garden, stub_model(Garden,
      :id => 42,
      :user => @user,
      :name => "My Awesome Allotment"
    ))
    @crop = assign(:crop, stub_model(Crop,
      :id => 99,
      :system_name => "Tomato"
    ))
    @planting = assign(:planting, stub_model(Planting,
      :garden => @garden,
      :crop => @crop,
      :quantity => 333,
      :description => "MyText *ITALIC*"
    ))
    render
  end

  it "renders the quantity planted" do
    rendered.should match(/333/)
  end

  it "renders the description" do
    rendered.should match(/MyText/)
  end

  it "renders markdown in the description" do
    assert_select "em", "ITALIC"
  end
end
