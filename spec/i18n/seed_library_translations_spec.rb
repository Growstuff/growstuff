# frozen_string_literal: true

require 'rails_helper'

RSpec.describe I18n do
  let(:sections) { %w(scope tabs past_sow_by empty other_tab library) }

  def key_paths(hash, prefix = nil)
    hash.flat_map do |key, value|
      path = [prefix, key].compact.join('.')
      value.is_a?(Hash) && %w(one other).exclude?(value.keys.first.to_s) ? key_paths(value, path) : [path]
    end
  end

  def keys_in(locale)
    sections.flat_map { |section| key_paths({ section => described_class.t("seeds.#{section}", locale:) }) }
  end

  describe '.t for the seed library' do
    %i(de es fr ja zh).each do |locale|
      context "with #{locale}" do
        it 'has every key English has' do
          expect(keys_in(locale)).to match_array(keys_in(:en))
        end

        it 'has twelve month names' do
          expect(described_class.t('seeds.library.months', locale:).size).to eq 12
        end

        [0, 1, 2, 5].each do |count|
          it "counts #{count} packets past their sow-by date" do
            expect { described_class.t('seeds.past_sow_by.count', count:, locale:) }.not_to raise_error
          end

          it "offers to show #{count} packets" do
            expect { described_class.t('seeds.past_sow_by.show_those', count:, locale:) }.not_to raise_error
          end
        end
      end
    end
  end
end
