# frozen_string_literal: true

require 'rails_helper'

describe CachedAbility do
  subject(:cached) { described_class.new(ability) }

  let(:ability) { instance_double(Ability) }
  let(:planting) { create(:planting) }

  it 'gives the answer of the ability it wraps' do
    allow(ability).to receive(:can?).with(:edit, planting).and_return(true)
    expect(cached.can?(:edit, planting)).to be true
  end

  it 'asks the ability a question only once' do
    allow(ability).to receive(:can?).and_return(false)
    2.times { cached.can?(:edit, planting) }
    expect(ability).to have_received(:can?).once
  end

  it 'remembers a no as well as a yes' do
    allow(ability).to receive(:can?).and_return(false)
    expect(2.times.map { cached.can?(:edit, planting) }).to eq [false, false]
  end
end
