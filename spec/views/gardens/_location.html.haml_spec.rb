# frozen_string_literal: true

require 'rails_helper'

describe 'gardens/_location' do
  subject { rendered }

  let(:member) { build_stubbed(:member) }

  before do
    allow(view).to receive(:current_member).and_return(member)
  end

  context 'when garden is persisted' do
    let(:garden) { build_stubbed(:garden, owner: member, location: 'Melbourne, Australia') }

    before do
      render partial: 'gardens/location', locals: { garden: }
    end

    it 'renders the localized heading' do
      expect(subject).to have_css('span.form-label', text: I18n.t('gardens.location.heading'))
    end

    it 'renders the garden location' do
      expect(subject).to have_css('#garden-location', text: 'Melbourne, Australia')
    end

    it 'renders the localized change button' do
      expect(subject).to have_content(I18n.t('gardens.location.change'))
    end

    it 'renders the localized remove button' do
      expect(subject).to have_button(I18n.t('gardens.location.remove'))
    end

    context 'without a location set' do
      let(:garden) { build_stubbed(:garden, owner: member, location: nil) }

      it 'renders the localized not_set placeholder' do
        expect(subject).to have_css('#garden-location', text: I18n.t('gardens.location.not_set'))
      end
    end
  end

  context 'when garden is not persisted' do
    let(:garden) { build(:garden, owner: member, location: nil) }

    context 'with member having a location' do
      let(:member) { build_stubbed(:member, location: 'Sydney, Australia') }

      before do
        render partial: 'gardens/location', locals: { garden: }
      end

      it 'renders the member location' do
        expect(subject).to have_content('Sydney, Australia')
      end

      it 'renders the localized heading' do
        expect(subject).to have_css('span.form-label', text: I18n.t('gardens.location.heading'))
      end
    end

    context 'without member having a location' do
      let(:member) { build_stubbed(:member, location: nil) }

      before do
        render partial: 'gardens/location', locals: { garden: }
      end

      it 'renders the localized not_set placeholder' do
        expect(subject).to have_content(I18n.t('gardens.location.not_set'))
      end
    end
  end
end
