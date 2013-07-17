require 'spec_helper'

describe 'plantings/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
    assign(:plantings, [
      FactoryGirl.create(:planting)
    ])
    render
  end

  it 'shows RSS feed title' do
    rendered.should contain "Recent plantings from all members"
  end

  it 'shows formatted content of posts' do
    rendered.should contain "This is a <em>really</em> good plant."
  end

end
