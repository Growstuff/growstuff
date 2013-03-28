require 'spec_helper'

describe 'notifier/notify.html.haml', :type => "view" do

  before(:each) do
    @notification = FactoryGirl.create(:notification)
    render
  end

  it 'should say that you have a message' do
    rendered.should contain 'You have received a message'
  end

  it 'should include notification metadata' do
    rendered.should contain @notification.sender.login_name
    rendered.should contain @notification.post.subject
  end

  it 'should contain a link to your inbox' do
    assert_select "a[href*=notifications]"
  end

  it 'should have fully qualified URLs' do
    # lots of lovely fully qualified URLs
    assert_select "a[href^=http]", { :minimum => 4 }
    # no relative URLs starting with /
    assert_select "a[href^=/]", { :count => 0 }
  end
end
