require 'rails_helper'

describe "comments/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    page = 1
    per_page = 2
    total_entries = 2
    comments = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
                      FactoryBot.create(:comment),
                      FactoryBot.create(:comment, body: 'ROFL')
                    ])
    end
    assign(:comments, comments)
    render
  end

  it "renders a list of comments" do
    render
    rendered.should have_content 'OMG LOL'
    rendered.should have_content 'ROFL'
  end

  it "contains an RSS feed link" do
    assert_select "a", href: comments_path(format: 'rss')
  end
end
