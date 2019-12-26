# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventHelper, type: :helper do
  let(:planting) { FactoryBot.create :planting }
  let(:harvest) { FactoryBot.create :harvest }
  let(:seed) { FactoryBot.create :seed }
  let(:post) { FactoryBot.create :post }
  let(:comment) { FactoryBot.create :comment }
  let(:photo) { FactoryBot.create :photo }

  subject { resolve_model(event) }
  describe 'plantings' do
    let(:event) { OpenStruct.new(id: planting.id, event_type: 'planting') }
    it { expect(subject).to eq planting }
    it { expect(event_description(event)).to have_text "planted #{planting.crop.name}" }
  end

  describe 'harvests' do
    let(:event) { OpenStruct.new(id: harvest.id, event_type: 'harvest') }
    it { expect(subject).to eq harvest }
    it { expect(event_description(event)).to have_text "harvested" }
  end

  describe 'seeds' do
    let(:event) { OpenStruct.new(id: seed.id, event_type: 'seed') }
    it { expect(subject).to eq seed }
    it { expect(event_description(event)).to have_text "saved #{seed.crop.name} seeds" }
  end

  describe 'posts' do
    let(:event) { OpenStruct.new(id: post.id, event_type: 'post') }
    it { expect(subject).to eq post }
    it { expect(event_description(event)).to have_text 'wrote a post' }
  end

  describe 'comments' do
    let(:event) { OpenStruct.new(id: comment.id, event_type: 'comment') }
    it { expect(subject).to eq comment }
    it { expect(event_description(event)).to have_text 'commented on' }
  end

  describe 'photos' do
    let(:event) { OpenStruct.new(id: photo.id, event_type: 'photo') }
    it { expect(subject).to eq photo }
    it { expect(event_description(event)).to have_text "took a photo" }
  end

  describe 'in_weeks' do
    it { expect(in_weeks(14)).to eq 2 }
    it { expect(in_weeks(15)).to eq 2 }
    it { expect(in_weeks(16)).to eq 2 }
    it { expect(in_weeks(17)).to eq 2 }
    it { expect(in_weeks(18)).to eq 3 }
    it { expect(in_weeks(19)).to eq 3 }
    it { expect(in_weeks(20)).to eq 3 }
    it { expect(in_weeks(21)).to eq 3 }
    it { expect(in_weeks(22)).to eq 3 }
  end
end
