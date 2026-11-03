# frozen_string_literal: true

require 'rails_helper'

describe 'gardens/_inactive_card' do
  subject { rendered }

  let(:owner) { build_stubbed(:member) }
  let(:garden) { build_stubbed(:garden, owner:, name: 'Secret Garden', description: 'A quiet place.') }
  let(:crops) { [build_stubbed(:crop, name: 'Tomato')] }
  let(:plantings) { crops.map { |crop| build_stubbed(:planting, crop:, garden:, owner:) } }

  before do
    allow(garden).to receive(:plantings).and_return(plantings)
    allow(view).to receive(:can?).with(:edit, garden).and_return(false)
    render partial: 'gardens/inactive_card', locals: { garden: }
  end

  it 'renders the localized image alt text' do
    expect(rendered).to have_css("img.card-img-top[alt='#{I18n.t('gardens.inactive_card.image_alt', name: garden.name)}']")
  end

  it 'renders the localized aria-label for grown crops list' do
    expect(rendered).to have_css("ul[aria-label='#{I18n.t('gardens.inactive_card.grown_here')}']")
  end

  context 'with more than 8 crops' do
    let(:crops) { (1..10).map { |i| build_stubbed(:crop, name: "Crop #{i}") } }

    it 'renders the localized more crops counter' do
      expect(rendered).to have_css(
        'li.inactive-garden-more',
        text: I18n.t('gardens.inactive_card.more_crops', count: 2)
      )
    end
  end
end
