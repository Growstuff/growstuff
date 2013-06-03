require 'spec_helper'

describe "comments/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    page = 1
    per_page = 2
    total_entries = 2
    comments = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
        FactoryGirl.create(:comment),
        FactoryGirl.create(:comment, :body => 'ROFL')
      ])
    end
    assign(:comments, comments)
    render
  end

  it "renders a list of comments" do
    render
    rendered.should contain 'OMG LOL'
    rendered.should contain 'ROFL'
  end
end
