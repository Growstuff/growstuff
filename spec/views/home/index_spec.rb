require 'spec_helper'

describe 'home/index.html.haml', :type => "view" do
  before(:each) do
    @member = FactoryGirl.create(:london_member)
    @member.updated_at = 2.days.ago
    assign(:interesting_members, [@member])

    @post = FactoryGirl.create(:post, :author => @member)
    assign(:posts, [@post])

    @planting = FactoryGirl.create(:planting, :owner => @member)
    assign(:plantings, [@planting])

    @crop = FactoryGirl.create(:crop)
    assign(:crops, [@crop])
    assign(:recent_crops, [@crop])
    assign(:seeds, [FactoryGirl.create(:tradable_seed)])
  end

  context 'logged out' do
    before(:each) do
      controller.stub(:current_user) { nil }
      render
    end

    it 'show interesting members' do
      rendered.should contain @member.login_name
      rendered.should contain @member.location
    end
  end

  context 'signed in' do
    before(:each) do
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it 'should say welcome' do
      rendered.should contain "Welcome to #{ENV['GROWSTUFF_SITE_NAME']}, #{@member.login_name}"
    end
  end

end
