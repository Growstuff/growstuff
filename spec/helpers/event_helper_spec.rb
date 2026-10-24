# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventHelper do
  subject { resolve_model(event) }

  let(:planting) { create(:planting) }
  let(:harvest) { create(:harvest) }
  let(:seed) { create(:seed) }
  let(:post) { create(:post) }
  let(:comment) { create(:comment) }
  let(:photo) { create(:photo) }

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

  describe 'jobs' do
    let(:job) { create(:job, name: 'Weed the beds', due_date:) }
    let(:due_date) { nil }
    let(:event) { OpenStruct.new(id: job.id, event_type: 'job') }

    it { expect(subject).to eq job }
    it { expect(event_description(event)).to have_text 'plans to do “Weed the beds”' }

    context 'when due later' do
      let(:due_date) { 3.months.from_now.to_date }

      it { expect(event_description(event)).to have_text "(due #{l(due_date, format: '%a %-d %b')})" }
    end

    context 'when overdue' do
      let(:due_date) { 1.month.ago.to_date }

      it { expect(event_description(event)).to have_no_text 'due' }
    end

    context 'when finished' do
      let(:job) { create(:job, name: 'Weed the beds', finished: true) }

      it { expect(event_description(event)).to have_text 'planned to do “Weed the beds”' }
    end
  end

  describe 'finished jobs' do
    let(:job) { create(:job, name: 'Weed the beds', finished: true) }
    let(:event) { OpenStruct.new(id: job.id, event_type: 'job_finished') }

    it { expect(subject).to eq job }
    it { expect(event_description(event)).to have_text 'did “Weed the beds”' }
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
