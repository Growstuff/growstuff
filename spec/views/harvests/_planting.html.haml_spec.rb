# frozen_string_literal: true

require 'rails_helper'

describe 'harvests/_planting' do
  subject { rendered }

  let(:member) { create(:member) }
  let(:garden) { create(:garden, owner: member) }
  let(:planting) { create(:planting, owner: member, garden:, overall_rating: nil) }
  let(:harvest) { create(:harvest, owner: member, planting: nil) }

  before do
    allow(view).to receive(:current_member).and_return(member)
    assign(:harvest, harvest)
  end

  context 'when harvest has no planting and matching plantings exist' do
    let(:matching_planting) { create(:planting, owner: member, garden:) }

    before do
      assign(:matching_plantings, [matching_planting])
      render
    end

    it 'renders the prompt asking if harvest is from one of the plantings' do
      expect(subject).to have_content(I18n.t('harvests.planting.is_this_from'))
    end

    it 'renders the save button' do
      expect(subject).to have_button(I18n.t('harvests.planting.save'))
    end
  end

  context 'when harvest has an unrated planting' do
    let(:harvest) { create(:harvest, owner: member, planting:) }

    before do
      assign(:matching_plantings, [])
      render
    end

    it 'renders the unrated planting notice' do
      expect(subject).to have_content(I18n.t('harvests.planting.unrated_notice'))
    end

    it 'renders the link to rate the planting' do
      expect(subject).to have_link(
        I18n.t('harvests.planting.rate_planting'),
        href: edit_planting_path(planting, anchor: 'planting_overall_rating')
      )
    end
  end
end
