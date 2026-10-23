# frozen_string_literal: true

require 'rails_helper'

describe JobIdeas::World do
  subject(:ideas) { described_class.new(member, today).ideas }

  let(:today) { Date.new(2026, 10, 23) }
  let(:member) { create(:london_member) }
  let(:neighbours) { neighbours_at(51.5, -100.0) }
  let(:due_date) { Date.new(2025, 10, 20) }

  # Saving a member geocodes their location again, so the coordinates are set after.
  def neighbours_at(latitude, longitude)
    create_list(:london_member, 3).each do |neighbour|
      neighbour.update_columns(latitude:, longitude:) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  before do
    neighbours.each do |neighbour|
      create(:job, :finished_without_time, owner: neighbour, name: 'Put out slug traps', due_date:)
    end
  end

  it 'has an idea for what enough gardeners at the same latitude did' do
    expect(ideas.map(&:name)).to eq ['Put out slug traps']
  end

  it 'is a world idea' do
    expect(ideas.first.kind).to eq :world
  end

  context 'with a job done this year' do
    let(:due_date) { Date.new(2026, 10, 12) }

    it 'counts it' do
      expect(ideas.map(&:name)).to eq ['Put out slug traps']
    end
  end

  context 'with gardeners at the opposite latitude' do
    let(:neighbours) { neighbours_at(-51.5, 0.0) }

    it { is_expected.to be_empty }
  end

  context 'with gardeners at a very different latitude in the same hemisphere' do
    let(:neighbours) { neighbours_at(30.0, 0.0) }

    it { is_expected.to be_empty }
  end

  context 'when the member has not said where they are' do
    let(:member) { create(:member) }

    it { is_expected.to be_empty }
  end
end
