# frozen_string_literal: true

require 'rails_helper'

describe NeighboursHelper do
  describe '#subject_path' do
    it 'is the owner\'s list of jobs, for a job' do
      job = create(:job)
      expect(helper.subject_path(job)).to eq member_jobs_path(job.owner)
    end

    it 'is its own page, for anything else' do
      planting = create(:planting)
      expect(helper.subject_path(planting)).to eq planting_path(planting)
    end
  end

  describe '#subject_label' do
    it 'names the job' do
      expect(helper.subject_label(build(:job, name: 'Net the berries'))).to eq 'the job Net the berries'
    end
  end

  describe '#season_start' do
    it 'is the first of the month a season begins in' do
      expect(helper.season_start(Date.new(2026, 10, 20))).to eq Date.new(2026, 9, 1)
    end

    it 'belongs to the year before in January' do
      expect(helper.season_start(Date.new(2027, 1, 15))).to eq Date.new(2026, 12, 1)
    end
  end

  describe '#season_heading' do
    let(:start) { Date.new(2026, 12, 1) }
    let(:member) { build(:member, latitude: -41.29) }

    it 'names the season in the southern hemisphere' do
      neighbours = instance_double(Neighbours, member:, hemispheres: [:southern])
      expect(strip_tags(helper.season_heading(start, neighbours)).squish).to eq 'Summer 2026'
    end

    it 'names both when the feed spans the world' do
      neighbours = instance_double(Neighbours, member:, hemispheres: %i(southern northern))
      expect(strip_tags(helper.season_heading(start, neighbours)).squish).to eq 'Summer 2026 · Winter in the northern hemisphere'
    end

    it 'gives each season its icon' do
      neighbours = instance_double(Neighbours, member:, hemispheres: %i(southern northern))
      expect(helper.season_heading(start, neighbours)).to include('fa-sun').and include('fa-snowflake')
    end

    it 'is nothing when nobody has said where they live' do
      neighbours = instance_double(Neighbours, member:, hemispheres: [])
      expect(helper.season_heading(start, neighbours)).to be_nil
    end
  end
end
