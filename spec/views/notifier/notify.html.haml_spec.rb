require 'rails_helper'

describe 'notifier/notify.html.haml', type: "view" do
  before(:each) do
    @notification = FactoryBot.create(:notification)
    @reply_link = "http://example.com"
    @signed_message = "EncryptedMessage"
    assign(:reply_link, @reply_link)
    render
  end

  it 'should say that you have a message' do
    rendered.should have_content 'You have received a message'
  end

  it 'should include notification metadata' do
    rendered.should have_content @notification.sender.login_name
    rendered.should have_content @notification.post.subject
  end

  it 'should include a reply link' do
    assert_select "a[href='#{@reply_link}']", text: /Reply/
  end

  it 'should contain a link to your inbox' do
    assert_select "a[href*='notifications']"
  end

  it 'should have fully qualified URLs' do
    # lots of lovely fully qualified URLs
    assert_select "a[href^='http']", minimum: 4
    # no relative URLs starting with /
    assert_select "a[href^='/']", count: 0
  end
end
