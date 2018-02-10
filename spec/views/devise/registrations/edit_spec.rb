require 'rails_helper'

describe 'devise/registrations/edit.html.haml', type: "view" do
  context "logged in" do
    before(:each) do
      controller.stub(:current_user) { nil }
      @member = FactoryBot.create(:member)
      controller.stub(:current_member) { @member }
      @view.stub(:resource).and_return(@member)
      @view.stub(:resource_name).and_return("member")
      @view.stub(:resource_class).and_return(Member)
      @view.stub(:devise_mapping).and_return(Devise.mappings[:member])
    end

    it 'should have some fields' do
      render
      rendered.should have_content 'Email'
    end

    context 'email section' do
      before(:each) do
        render
      end

      it 'has a checkbox for email notifications' do
        assert_select "input[id=member_send_notification_email][type=checkbox]"
      end

      it 'has a checkbox for newsletter subscription' do
        assert_select "input[id=member_newsletter][type=checkbox]"
      end
    end

    context 'profile section' do
      before(:each) do
        render
      end

      it 'shows show_email checkbox' do
        assert_select "input[id=member_show_email][type=checkbox]"
      end

      it "contains a gravatar icon" do
        assert_select "img", src: /gravatar\.com\/avatar/
      end

      it 'contains a link to gravatar.com' do
        assert_select "a", href: /gravatar\.com/
      end

      it 'shows bio field' do
        assert_select "textarea[id=member_bio]"
      end

      it 'shows location field' do
        assert_select "input[id=member_location][type=text]"
      end
    end

    context 'other sites section' do
      context 'not connected to twitter' do
        it 'has a link to connect' do
          render
          assert_select "a", "Connect to Twitter"
        end
      end
      context 'connected to twitter' do
        before(:each) do
          @twitter_auth = FactoryBot.create(:authentication, member: @member)
          render
        end
        it 'has a link to twitter profile' do
          assert_select "a", href: "http://twitter.com/#{@twitter_auth.name}"
        end
        it 'has a link to disconnect' do
          render
          assert_select "a", href: @twitter_auth, text: "Disconnect"
        end
      end

      context 'not connected to flickr' do
        it 'has a link to connect' do
          render
          assert_select "a", "Connect to Flickr"
        end
      end
      context 'connected to flickr' do
        before(:each) do
          @flickr_auth = FactoryBot.create(:flickr_authentication, member: @member)
          render
        end
        it 'has a link to flickr photostream' do
          assert_select "a", href: "http://flickr.com/photos/#{@flickr_auth.uid}"
        end
        it 'has a link to disconnect' do
          render
          assert_select "a", href: @flickr_auth, text: "Disconnect"
        end
      end
    end
  end
end
