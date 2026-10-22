# frozen_string_literal: true

require 'rails_helper'

describe 'Layout on a phone', :js, :phone do
  subject { page }

  let(:member) { create(:member) }

  before { resize_to_phone }

  shared_examples 'fits the screen' do
    it { is_expected.to have_no_horizontal_overflow }
  end

  context 'with the signed out home page' do
    before { visit root_path }

    it_behaves_like 'fits the screen'
  end

  context 'with a veteran gardener\'s dashboard' do
    before do
      create(:planting, owner: member, garden: member.gardens.first, planted_at: 3.years.ago)
      create(:harvest, owner: member, harvested_at: 1.month.ago)
      login_as member
      visit root_path
    end

    it_behaves_like 'fits the screen'
  end

  context 'with the crops list' do
    before do
      create(:tomato)
      visit crops_path
    end

    it_behaves_like 'fits the screen'
  end
end
