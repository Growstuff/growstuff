# frozen_string_literal: true

require 'rails_helper'

describe 'devise/registrations/edit.html.haml', type: "view" do
  context "logged in" do
    before do
      controller.stub(:current_user) { nil }
      @member = create(:member)
      controller.stub(:current_member) { @member }
      @view.stub(:resource).and_return(@member)
      @view.stub(:resource_name).and_return("member")
      @view.stub(:resource_class).and_return(Member)
      @view.stub(:devise_mapping).and_return(Devise.mappings[:member])
    end

    it 'has some fields' do
      render
      expect(rendered).to have_content 'Email'
    end

    context 'email section' do
      before do
        render
      end

      it 'has a checkbox for email notifications' do
        assert_select "input[id=member_send_notification_email][type=checkbox]"
      end
    end

    context 'profile section' do
      before do
        render
      end

      it 'shows show_email checkbox' do
        assert_select "input[id=member_show_email][type=checkbox]"
      end

      it "contains a gravatar icon" do
        assert_select "img", src: %r{gravatar\.com/avatar}
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

    context 'with linked Mastodon profiles' do
      let(:first_name) { ['@alice', 'mastodon.social'].join('@') }
      let(:second_name) { ['@gardener', 'example.social'].join('@') }

      before do
        create(:mastodon_authentication, member: @member, name: first_name)
        create(:mastodon_authentication, member: @member, uid: ['222', 'example.social'].join('@'), name: second_name)
        render
      end

      it 'shows all linked profiles in the profile tab' do
        expect(rendered).to have_css('#profile ul[aria-labelledby="mastodon-profiles-label"] li', text: /#{Regexp.escape(first_name)}|#{Regexp.escape(second_name)}/, count: 2)
      end

      it 'does not provide editable Mastodon fields in the profile tab' do
        expect(rendered).not_to have_css('#profile input[name*="mastodon"]')
      end

      it 'explains where to manage connections' do
        expect(rendered).to have_css('#profile .form-text', text: 'Linked accounts are read-only here. Manage them in the Apps tab.')
      end
    end

    context 'without linked Mastodon profiles' do
      it 'does not show a Mastodon profile list' do
        render
        expect(rendered).not_to have_css('#profile ul[aria-labelledby="mastodon-profiles-label"]')
      end
    end

    context 'other sites section' do
      context 'not connected to flickr' do
        it 'has a button to connect' do
          render
          expect(rendered).to have_button 'Connect to Flickr'
        end
      end

      context 'connected to flickr' do
        before do
          @flickr_auth = create(:flickr_authentication, member: @member)
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
