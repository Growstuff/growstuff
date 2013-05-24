require 'spec_helper'

describe "plantings/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @member   = FactoryGirl.create(:member)
    @garden = FactoryGirl.create(:garden, :owner => @member)
    @tomato = FactoryGirl.create(:tomato)
    @maize  = FactoryGirl.create(:maize)
    page = 1
    per_page = 2
    total_entries = 2
    plantings = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
        FactoryGirl.create(:planting,
          :garden => @garden,
          :crop => @tomato
        ),
        FactoryGirl.create(:planting,
          :garden => @garden,
          :crop => @maize,
          :description => '',
          :planted_at => Time.local(2013, 1, 13)
        )
      ])
    end
    assign(:plantings, plantings)
    render
  end

  it "renders a list of plantings" do
    rendered.should contain 'Tomato'
    rendered.should contain 'Maize'
    rendered.should contain /member\d+'s Springfield Community Garden/
  end

  it "shows descriptions where they exist" do
    rendered.should contain "This is a"
  end

  it "displays planting time" do
    rendered.should contain 'January 13, 2013'
  end

  it "renders markdown in the description" do
    assert_select "em", "really"
  end

end
