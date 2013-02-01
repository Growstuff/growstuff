require 'spec_helper'

describe 'plantings/index.rss.builder', :type => "view" do
  before(:each) do
    controller.stub(:current_user) { Member.new }
    assign(:recent_plantings, [
      FactoryGirl.create(:planting)
    ])
    render
  end

  it 'shows RSS feed title' do
    rendered.should contain "Recent plantings from all members"
  end

  it 'shows content of posts' do
    rendered.should contain "This is a *really* good plant."
  end

end
