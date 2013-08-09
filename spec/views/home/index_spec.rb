require 'spec_helper'

describe 'home/index.html.haml', :type => "view" do
  before(:each) do
    @member = FactoryGirl.create(:london_member)
    @member.updated_at = 2.days.ago
    assign(:interesting_members, [@member])

    @post = FactoryGirl.create(:post, :author => @member)
    assign(:posts, [@post])

    @planting = FactoryGirl.create(:planting, :garden => @member.gardens.first)
    assign(:plantings, [@planting])

    assign(:recent_crops, [FactoryGirl.create(:crop)])
    assign(:seeds, [FactoryGirl.create(:tradable_seed)])
  end
  context 'logged out' do
    before(:each) do
      controller.stub(:current_user) { nil }
      render
    end

    it 'has description' do
      rendered.should contain 'is a community of food gardeners'
    end

    it 'show interesting members' do
      rendered.should contain @member.login_name
      rendered.should contain @member.location
    end
  end

  context 'logged in' do
    before(:each) do
      controller.stub(:current_user) { @member }
      sign_in @member
      assign(:member, @member)
      render
    end

    it 'should say welcome' do
      render
      rendered.should contain "Welcome to #{Growstuff::Application.config.site_name}, #{@member.login_name}"
    end

  end
end
