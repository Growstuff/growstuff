require 'rails_helper'

describe "notifications/index" do
  before(:each) do
    @member = FactoryBot.create(:member)
    controller.stub(:current_user) { @member }
  end

  context "ordinary notifications" do
    before(:each) do
      @notification = FactoryBot.create(:notification, sender: @member,
                                                       recipient: @member)
      assign(:notifications, Kaminari.paginate_array([@notification, @notification]).page(1))
      render
    end

    it "renders a list of notifications" do
      assert_select "table"
      assert_select "tr>td", text: @notification.sender.to_s, count: 2
      assert_select "tr>td", text: @notification.subject, count: 2
    end

    it "links to sender's profile" do
      assert_select "a", href: member_path(@notification.sender)
    end
  end

  context "no subject" do
    it "shows (no subject)" do
      @notification = FactoryBot.create(:notification,
        sender: @member, recipient: @member, subject: nil)
      assign(:notifications, Kaminari.paginate_array([@notification]).page(1))
      render
      rendered.should have_content "(no subject)"
    end
  end

  context "whitespace-only subject" do
    it "shows (no subject)" do
      @notification = FactoryBot.create(:notification,
        sender: @member, recipient: @member, subject: "   ")
      assign(:notifications, Kaminari.paginate_array([@notification]).page(1))
      render
      rendered.should have_content "(no subject)"
    end
  end
end
