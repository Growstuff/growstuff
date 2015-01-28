require 'rails_helper'

describe "members/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    page = 1
    per_page = 2
    total_entries = 2
    @member = FactoryGirl.create(:london_member)
    members = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([ @member, @member ])
    end
    assign(:members, members)
    render
  end

  it "contains two gravatar icons" do
    assert_select "img", :src => /gravatar\.com\/avatar/, :count => 2
  end

  it 'contains member locations' do
    rendered.should have_content @member.location
  end

end
