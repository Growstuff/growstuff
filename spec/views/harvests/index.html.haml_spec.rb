require 'spec_helper'

describe "harvests/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @member   = FactoryGirl.create(:member)
    @tomato = FactoryGirl.create(:tomato)
    @maize  = FactoryGirl.create(:maize)
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
    assert_select "tr>td", :text => @tomato.system_name
    assert_select "tr>td", :text => @maize.system_name
  end
end
