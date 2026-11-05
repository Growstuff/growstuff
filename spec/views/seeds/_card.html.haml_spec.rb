# frozen_string_literal: true

require 'rails_helper'

describe 'seeds/_card' do
  subject { rendered }

  let(:owner) { create(:member, login_name: 'seedsaver', location: 'Portland') }
  let(:crop) { create(:crop, name: 'Tomato') }
  let(:seed) do
    create(
      :seed,
      owner:,
      crop:,
      saved_at: Date.new(2024, 8, 15),
      plant_before: Date.new(2027, 3, 1),
      quantity: 50,
      tradable_to: 'locally'
    )
  end

  before do
    render partial: 'seeds/card', locals: { seed: }
  end

  it 'renders the localized saved year' do
    expect(subject).to have_content(I18n.t('seeds.card.saved', year: 2024))
  end

  it 'renders the localized seeds saved by owner' do
    expect(subject).to have_content(I18n.t('seeds.card.seeds_saved_by', owner: 'seedsaver'))
  end

  it 'renders the localized quantity' do
    expect(subject).to have_content(I18n.t('seeds.card.quantity', count: 50))
  end

  it 'renders the localized sow before year' do
    expect(subject).to have_content(I18n.t('seeds.card.sow_before', year: 2027))
  end

  it 'renders the localized will trade info' do
    expect(subject).to have_content(I18n.t('seeds.card.will_trade', tradable_to: 'locally'))
  end
end
