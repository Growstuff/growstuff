# frozen_string_literal: true

require 'rails_helper'

describe "timeline", js: true do
  let(:member) { FactoryBot.create :member }
  let(:friend1) { FactoryBot.create :member }
  let(:friend2) { FactoryBot.create :member }

  before do
    member.followed << friend1
    member.followed << friend2
  end

  describe 'visit timeline' do
    let!(:friend_planting) { FactoryBot.create :planting, owner: friend1, planted_at: 1.day.ago }
    let!(:friend_harvest) { FactoryBot.create :planting, owner: friend2, planted_at: 3.years.ago }
    let!(:finished_planting) { FactoryBot.create :finished_planting, owner: friend1 }
    let!(:no_planted_at_planting) { FactoryBot.create :planting, owner: friend2, planted_at: nil }

    before do
      login_as(member)
      visit timeline_index_path
    end

    describe 'show the activity' do
      it { expect(page).to have_link href: planting_path(friend_planting) }
      it { expect(page).to have_link href: planting_path(friend_harvest) }
      it { expect(page).to have_link href: planting_path(finished_planting) }
      it { expect(page).not_to have_link href: planting_path(no_planted_at_planting) }
    end
    describe 'shows the friends you follow' do
      it { expect(page).to have_link href: member_path(friend1) }
      it { expect(page).to have_link href: member_path(friend2) }
    end
  end
end
