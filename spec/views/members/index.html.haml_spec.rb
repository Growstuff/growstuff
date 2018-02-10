require 'rails_helper'

describe "members/index" do
  let(:member) { FactoryBot.create(:london_member) }

  before(:each) do
    controller.stub(:current_user) { nil }
    page = 1
    per_page = 2
    total_entries = 2
    members = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([member, member])
    end
    assign(:members, members)
    render
  end

  it "contains two gravatar icons" do
    assert_select "img", src: /gravatar\.com\/avatar/, count: 2
  end

  it 'contains member locations' do
    expect(rendered).to have_content member.location
  end
end
