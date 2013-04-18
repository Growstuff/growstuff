require 'spec_helper'

describe 'devise/registrations/edit.html.haml', :type => "view" do

  context "logged in" do
    before(:each) do
      controller.stub(:current_user) { nil }
      @member = FactoryGirl.create(:member)
      controller.stub(:current_member) { @member }
      @view.stub(:resource).and_return(@member)
      @view.stub(:resource_name).and_return("member")
      @view.stub(:resource_class).and_return(Member)
      @view.stub(:devise_mapping).and_return(Devise.mappings[:member])
    end

    it 'should have some fields' do
      render
      rendered.should contain 'Email'
    end

    context 'email section' do
      before(:each) do
        render
      end

      it 'has a heading' do
        assert_select "h2", "Email settings"
      end

      it 'has a checkbox for email notifications' do
        assert_select "input[id=member_send_notification_email][type=checkbox]"
      end
    end

    context 'profile section' do
      before(:each) do
        render
      end

      it 'has a heading' do
        assert_select "h2", "Profile details"
      end
      it 'shows show_email checkbox' do
        assert_select "input[id=member_show_email][type=checkbox]"
      end
      it "contains a gravatar icon" do
        assert_select "img", :src => /gravatar\.com\/avatar/
      end
      it 'contains a link to gravatar.com' do
        assert_select "a", :href => /gravatar\.com/
      end
      it 'shows location field' do
        assert_select "input[id=member_location][type=text]"
      end
    end

    context 'other sites section' do
      it 'has a heading' do
        render
        assert_select "h2", "Linked accounts"
      end
      context 'not connected to twitter' do
        it 'has a link to connect' do
          render
          assert_select "a", "Connect to Twitter"
        end
      end
      context 'connected to twitter' do
        before(:each) do
          @twitter_auth = FactoryGirl.create(:authentication, :member => @member)
          render
        end
        it 'has a link to twitter profile' do
          assert_select "a", :href => "http://twitter.com/#{@twitter_auth.name}"
        end
        it 'has a link to disconnect' do
          render
          assert_select "a", :href => @twitter_auth, :text => "Disconnect"
        end
      end
    end

    it 'should have a password section' do
      render
      assert_select "h2", "Change password"
    end

  end

end
