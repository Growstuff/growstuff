# frozen_string_literal: true

require 'rails_helper'

describe JobIdeas::Nearby do
  subject(:ideas) { described_class.new(member, today).ideas }

  let(:today) { Date.new(2026, 10, 23) }
  let(:member) { create(:london_member) }
  let(:neighbours) { create_list(:london_member, 3) }

  before do
    neighbours.each do |neighbour|
      create(:job, :finished_without_time, owner: neighbour, name: 'Put out slug traps', due_date: Date.new(2026, 10, 20))
    end
  end

  it 'has an idea for what enough of them did' do
    expect(ideas.map(&:name)).to eq ['Put out slug traps']
  end

  it 'counts the gardeners' do
    expect(ideas.first.gardeners).to eq 3
  end

  it 'has no crop for a job about none' do
    expect(ideas.first.crop).to be_nil
  end

  it 'says nothing of how many grow it' do
    expect(ideas.first.of).to be_nil
  end

  context 'with gardeners far away' do
    let(:neighbours) { create_list(:south_pole_member, 3) }

    it { is_expected.to be_empty }
  end

  context 'when the member has not said where they are' do
    let(:member) { create(:member) }

    it { is_expected.to be_empty }
  end
end
