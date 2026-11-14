# frozen_string_literal: true

require 'rails_helper'

describe IconsHelper do
  describe '#icon' do
    subject(:html) { helper.icon('fas', 'heart') }

    it { is_expected.to have_css('i.fas.fa-heart[aria-hidden="true"]') }

    context 'with text' do
      subject(:html) { helper.icon('fas', 'heart', 'Like') }

      it { is_expected.to end_with(' Like') }
    end

    context 'with a class option' do
      subject(:html) { helper.icon('far', 'sun', class: 'big') }

      it { is_expected.to have_css('i.far.fa-sun.big') }
    end
  end

  describe '#planting_event_icon' do
    it 'is the planting icon for a sowing and for a planting' do
      expect(helper.planting_event_icon(:sown)).to eq helper.planting_icon
      expect(helper.planting_event_icon(:planted)).to eq helper.planting_icon
    end

    it 'is the icon the neighbours feed uses for a move to another garden' do
      expect(helper.planting_event_icon(:transplanted)).to eq helper.growing_icon
    end

    it 'is the harvest icon for both harvests' do
      expect(helper.planting_event_icon(:first_harvest)).to eq helper.harvest_icon
      expect(helper.planting_event_icon(:last_harvest)).to eq helper.harvest_icon
    end

    it 'is the finished icon for a finish and for a failure' do
      expect(helper.planting_event_icon(:finished)).to eq helper.finished_icon
      expect(helper.planting_event_icon(:failed)).to eq helper.finished_icon
    end
  end
end
