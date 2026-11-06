# frozen_string_literal: true

require 'rails_helper'

describe SeedSourceHelper do
  let(:seed) { build(:seed, source:, saved_at:, owner: build(:member, login_name: 'shiny')) }
  let(:saved_at) { nil }
  let(:page) { Capybara.string(helper.seed_source_ribbon(seed).to_s) }

  {
    'retail outlet'                    => %w(bought Bought),
    'seed catalogue'                   => %w(catalogue Catalogue),
    'seed bank or similar institution' => ['bank', 'Seed bank'],
    'traded from another person'       => %w(traded Traded)
  }.each do |source, (kind, words)|
    context "with a source of #{source}" do
      let(:source) { source }

      it("is a #{kind} ribbon") { expect(page).to have_css(".seed-source-ribbon.seed-source-ribbon--#{kind}", text: words) }
      it('says the whole source when hovered') { expect(page).to have_css("[title='Source: #{source}']") }
    end
  end

  context 'with seed the grower saved, in a year' do
    let(:source) { 'my own seed saving' }
    let(:saved_at) { Date.new(2026, 9, 24) }

    it('says who saved it, and when') do
      expect(page).to have_css('.seed-source-ribbon--saved', text: 'Saved by shiny in 2026')
    end
  end

  context 'with seed the grower saved, in no known year' do
    let(:source) { 'my own seed saving' }

    it('says only who saved it') { expect(page).to have_css('.seed-source-ribbon--saved', exact_text: 'Saved by shiny') }
  end

  context 'with an unknown source' do
    let(:source) { 'other/unknown' }

    it('has no ribbon') { expect(helper.seed_source_ribbon(seed)).to be_nil }
  end

  context 'with no source' do
    let(:source) { nil }

    it('has no ribbon') { expect(helper.seed_source_ribbon(seed)).to be_nil }
  end

  context 'as a badge' do
    let(:source) { 'retail outlet' }
    let(:page) { Capybara.string(helper.seed_source_ribbon(seed, ribbon: false).to_s) }

    it('is a badge of the same words') { expect(page).to have_css('.badge.seed-source-badge', text: 'Bought') }
    it('is not a ribbon') { expect(page).to have_no_css('.seed-source-ribbon') }
  end

  describe '#seed_source_control' do
    let(:page) { Capybara.string(helper.seed_source_control(seed).to_s) }
    let(:source) { 'retail outlet' }

    context 'for someone who cannot change the seed' do
      before { allow(helper).to receive(:can?).with(:update, seed).and_return(false) }

      it('is the plain ribbon') { expect(page).to have_css('span.seed-source-ribbon--bought', text: 'Bought') }
      it('has no choices') { expect(page).to have_no_css('.dropdown-menu') }
    end

    context 'for the grower' do
      before do
        allow(helper).to receive(:can?).with(:update, seed).and_return(true)
        allow(helper).to receive(:seed_path) { |_seed, params| "/seeds/1?#{params.to_query}" }
      end

      it('is a button that opens the choices') do
        expect(page).to have_button('Bought', class: 'seed-source-ribbon--bought')
      end

      it('offers every source there is') { expect(page).to have_css('.dropdown-menu a', count: Seed::SOURCE_VALUES.size) }
      it('lights the one it is') { expect(page).to have_css('.dropdown-item.active', text: 'Retail outlet') }

      it('changes the source with a put') do
        expect(page).to have_css('a.dropdown-item[data-method=put][href*="seed%5Bsource%5D=seed+catalogue"]', text: 'Seed catalogue')
      end

      context 'when the source is not known' do
        let(:source) { 'other/unknown' }

        it('has a faint "Where from?" to set it') { expect(page).to have_button('Where from?', class: 'seed-source-ribbon--unset') }
      end
    end
  end

  it 'has a ribbon for every source there is, but the unknown one' do
    expect(described_class::SOURCE_RIBBONS.keys).to match_array(Seed::SOURCE_VALUES - ['other/unknown'])
  end
end
