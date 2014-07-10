require 'spec_helper'

describe "harvests/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @member   = FactoryGirl.create(:member)
    @tomato = FactoryGirl.create(:tomato)
    @maize  = FactoryGirl.create(:maize)
    @pp = FactoryGirl.create(:plant_part)
    page = 1
    per_page = 2
    total_entries = 2
    harvests = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
        FactoryGirl.create(:harvest,
          :crop => @tomato,
          :owner => @member
        ),
        FactoryGirl.create(:harvest,
          :crop => @maize,
          :plant_part => @pp,
          :owner => @member
        )
      ])
    end
    assign(:harvests, harvests)
    render
  end

  it "renders a list of harvests" do
    render
    assert_select "tr>td", :text => @member.login_name
    assert_select "tr>td", :text => @tomato.name
    assert_select "tr>td", :text => @maize.name
    assert_select "tr>td", :text => @pp.name
  end

  it "provides data links" do
    render
    rendered.should contain "The data on this page is available in the following formats:"
    assert_select "a", :href => harvests_path(:format => 'csv')
    assert_select "a", :href => harvests_path(:format => 'json')
  end
end
