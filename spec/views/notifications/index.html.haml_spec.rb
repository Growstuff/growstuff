## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe "notifications/index" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    controller.stub(:current_user) { @member }
  end

  context "ordinary notifications" do
    before(:each) do
      @notification = FactoryGirl.create(:notification, sender: @member,
                                         recipient: @member)
      assign(:notifications, Kaminari.paginate_array([ @notification, @notification ]).page(1))
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
      @notification = FactoryGirl.create(:notification,
         sender: @member, recipient: @member, subject: nil)
      assign(:notifications, Kaminari.paginate_array([@notification]).page(1))
      render
      rendered.should have_content "(no subject)"
    end
  end

  context "whitespace-only subject" do
    it "shows (no subject)" do
      @notification = FactoryGirl.create(:notification,
         sender: @member, recipient: @member, subject: "   ")
      assign(:notifications, Kaminari.paginate_array([@notification]).page(1))
      render
      rendered.should have_content "(no subject)"
    end
  end

end
