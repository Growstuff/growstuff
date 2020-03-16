# frozen_string_literal: true

require 'rails_helper'

describe 'home/index.html.haml', type: "view" do
  before do
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

    Crop.reindex
  end

  context 'logged out' do
    before do
      controller.stub(:current_user) { nil }
      render
    end

    it 'show interesting members' do
      rendered.should have_content @member.login_name
      rendered.should have_content @member.location
    end
  end

  context 'signed in' do
    before do
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end
  end
end
