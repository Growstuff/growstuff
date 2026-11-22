# frozen_string_literal: true

require 'rails_helper'

describe AlternateNamesHelper do
  subject { helper.alternate_name_language(alternate_name) }

  let(:alternate_name) { AlternateName.new }
  let(:member) { build(:member, settings: { 'locale' => locale }) }
  let(:locale) { nil }

  before do
    allow(helper).to receive(:current_member).and_return(member)
  end

  it 'leaves the language blank without a saved locale' do
    expect(subject).to be_nil
  end

  context 'with a saved locale' do
    let(:locale) { 'fr' }

    it 'selects the matching language code' do
      expect(subject).to eq('FR')
    end

    context 'with a regional locale' do
      let(:locale) { 'pt-BR' }

      it 'selects the base language' do
        expect(subject).to eq('PT')
      end
    end

    context 'with an unavailable language' do
      let(:locale) { 'unknown' }

      it 'leaves the language blank' do
        expect(subject).to be_nil
      end
    end

    context 'with a selected language' do
      let(:alternate_name) { AlternateName.new(language: 'DE') }

      it 'preserves the selected language' do
        expect(subject).to eq('DE')
      end
    end

    context 'when editing an alternate name' do
      let(:alternate_name) { create(:alternate_name, language: 'EN') }

      it 'preserves the saved language' do
        expect(subject).to eq('EN')
      end
    end
  end

  context 'without a signed-in member' do
    let(:member) { nil }

    it 'leaves the language blank' do
      expect(subject).to be_nil
    end
  end
end
