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
end
