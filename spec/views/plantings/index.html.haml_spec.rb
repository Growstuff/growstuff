require 'spec_helper'

describe "plantings/index" do
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
      :id => 98,
      :system_name => "Tomato"
    ))
    @crop2 = assign(:crop, stub_model(Crop,
      :id => 99,
      :system_name => "Maize"
    ))
    assign(:recent_plantings, [ stub_model(Planting,
        :garden => @garden,
        :crop => @crop,
        :planted_at => '2008-01-05 12:34:56',
        :quantity => 3,
        :description => "MyText",
        :created_at => Time.now
      ),
      stub_model(Planting,
        :garden => @garden,
        :crop => @crop2,
        :description => '',
        :created_at => Time.now
      )
    ])
    render
  end

  it "renders a list of plantings" do
    rendered.should contain 'Tomato'
    rendered.should contain 'Maize'
    rendered.should contain "blah's My Awesome Allotment"
  end

  it "shows descriptions where they exist" do
    rendered.should contain "MyText"
  end

  it "shows filler when there is no description" do
    rendered.should contain "No description given"
  end

  it "displays planting time" do
    rendered.should contain '2008-01-05 12:34:56'
  end

end
