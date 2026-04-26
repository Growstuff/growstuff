# frozen_string_literal: true

require 'rails_helper'

describe 'home/index.html.haml', type: "view" do
  before do
    @member = create(:london_member)
    @member.updated_at = 2.days.ago
    assign(:interesting_members, [@member])

    @post = create(:post, author: @member)
    assign(:posts, [@post])

    @planting = create(:planting, owner: @member)
    assign(:plantings, [@planting])

    @crop = create(:crop)
    assign(:crops, [@crop])
    assign(:recent_crops, [@crop])
    assign(:seeds, [create(:tradable_seed)])

    Crop.reindex
  end

  context 'logged out' do
    before do
      controller.stub(:current_user) { nil }
      render
    end

    it 'show interesting members' do
      expect(rendered).to have_content @member.login_name
      expect(rendered).to have_content @member.location
    end
  end
end
