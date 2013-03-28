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
      render
    end

    it 'should have some fields' do
        rendered.should contain 'Email'
    end

    context 'email section' do
      it 'has a heading' do
        assert_select "h2", "Email settings"
      end
    end

    context 'profile section' do
      it 'has a heading' do
        assert_select "h2", "Profile details"
      end
      it 'shows show_email checkbox' do
        assert_select "input[id=member_show_email][type=checkbox]"
      end
      it 'shows location field' do
        assert_select "input[id=member_location][type=text]"
      end
      it 'shows full name field' do
        assert_select "input[id=member_full_name][type=text]"
      end
      it 'shows about me field' do
        assert_select "textarea#member_about_me"
      end
      it 'shows gardening since field' do
        assert_select "input[id=member_gardening_since][type=text]"
      end
      it "shows 'I wish I could grow' field" do
        assert_select "input[id=member_wish_i_could_grow][type=text]"
      end
      it "shows gardening clothes field" do
        assert_select "input[id=member_gardening_clothes][type=text]"
      end
    end

    it 'should have a password section' do
      assert_select "h2", "Change password"
    end

  end

end
