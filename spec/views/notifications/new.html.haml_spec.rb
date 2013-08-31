require 'spec_helper'

describe "notifications/new" do
  before(:each) do
    @recipient = FactoryGirl.create(:member)
    @sender = FactoryGirl.create(:member)
    @notification = FactoryGirl.create(:notification, :recipient_id => @recipient.id, :sender_id => @sender.id)
    assign(:notification, @notification)
    sign_in @sender
    controller.stub(:current_user) { @sender}
  end

  it "renders new message form" do
    render
    assert_select "form", :action => notifications_path, :method => "notification" do
      assert_select "input#notification_subject", :name => "notification[subject]"
      assert_select "textarea#notification_body", :name => "notification[body]"
    end
  end

  it "tells you who the recipient is" do
    render
    rendered.should contain @recipient.login_name
  end

  it "puts the recipient in a hidden field" do
    render
    assert_select "input#notification_recipient_id[type=hidden]", :name => "notification[recipient_id]"
  end

  it "fills in the subject if provided" do
    assign(:subject, 'Foo')
    render
    assert_select "input#notification_subject", :value => "Foo"
  end

  it "leaves the subject empty if not provided" do
    render
    assert_select "input#notification_subject", :value => ""
  end

  it "Tells you to write your message here" do
    render
    rendered.should contain "Type your message here"
  end

  it 'shows markdown help' do
    render
    rendered.should contain 'Markdown'
  end

  context "replying to existing message" do
    before :each do
      @in_reply_to = FactoryGirl.create(
        :notification,
        :recipient_id => @sender.id,
        :sender_id => @recipient.id,
        :body => "This message demands an immediate reply"
      )
      assign(:in_reply_to, @in_reply_to)
    end

    it "shows the text of the previous notification" do
     render
     rendered.should contain @in_reply_to.body
    end
  end
end
