require 'rails_helper'

describe 'home/index.html.haml', type: "view" do
  before(:each) do
    @member = FactoryBot.create(:london_member)
    @member.updated_at = 2.days.ago
    assign(:interesting_members, [@member])

    @post = FactoryBot.create(:post, author: @member)
    assign(:posts, [@post])

    @planting = FactoryBot.create(:planting, owner: @member)
    assign(:plantings, [@planting])

    @crop = FactoryBot.create(:crop)
    assign(:crops, [@crop])
    assign(:recent_crops, [@crop])
    assign(:seeds, [FactoryBot.create(:tradable_seed)])
  end

  context 'logged out' do
    before(:each) do
      controller.stub(:current_user) { nil }
      render
    end

    it 'show interesting members' do
      rendered.should have_content @member.login_name
      rendered.should have_content @member.location
    end
  end

  context 'signed in' do
    before(:each) do
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it 'should say welcome' do
      rendered.should have_content "Welcome to #{ENV['GROWSTUFF_SITE_NAME']}, #{@member.login_name}"
    end
  end
end
