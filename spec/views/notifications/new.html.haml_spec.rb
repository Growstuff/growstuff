require 'rails_helper'

describe "notifications/new" do
  before(:each) do
    @recipient = FactoryBot.create(:member)
    @sender = FactoryBot.create(:member)
    assign(:notification, FactoryBot.create(:notification, recipient_id: @recipient.id, sender_id: @sender.id))
    sign_in @sender
    controller.stub(:current_user) { @sender }
  end

  it "renders new message form" do
    render
    assert_select "form", action: notifications_path, method: "notification" do
      assert_select "input#notification_subject", name: "notification[subject]"
      assert_select "textarea#notification_body", name: "notification[body]"
    end
  end

  it "tells you who the recipient is" do
    render
    rendered.should have_content @recipient.login_name
  end

  it "puts the recipient in a hidden field" do
    render
    assert_select "input#notification_recipient_id[type=hidden]", name: "notification[recipient_id]"
  end

  it "fills in the subject if provided" do
    assign(:subject, 'Foo')
    render
    assert_select "input#notification_subject", value: "Foo"
  end

  it "leaves the subject empty if not provided" do
    render
    assert_select "input#notification_subject", value: ""
  end

  it "Tells you to write your message here" do
    render
    rendered.should have_content "Type your message here"
  end

  it 'shows markdown help' do
    render
    rendered.should have_content 'Markdown'
  end
end
