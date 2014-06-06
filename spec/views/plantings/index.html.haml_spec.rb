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
          :crop => @tomato,
          :owner => @member
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
    rendered.should contain @tomato.name
    rendered.should contain @maize.name
    rendered.should contain @member.login_name
    rendered.should contain @garden.name
  end

  it "shows descriptions where they exist" do
    rendered.should contain "This is a"
  end

  it "displays planting time" do
    rendered.should contain 'January 13, 2013'
  end

  it "provides data links" do
    render
    rendered.should contain "The data on this page is available in the following formats:"
    assert_select "a", :href => plantings_path(:format => 'csv')
    assert_select "a", :href => plantings_path(:format => 'json')
    assert_select "a", :href => plantings_path(:format => 'rss')
  end

end
