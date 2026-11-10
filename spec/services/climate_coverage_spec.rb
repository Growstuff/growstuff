# frozen_string_literal: true

require 'rails_helper'

describe ClimateCoverage do
  subject(:coverage) { described_class.new(Member.all) }

  let!(:covered) { create(:member).tap { |member| member.update_columns(latitude: -41.3, longitude: 174.8) } } # rubocop:disable Rails/SkipsModelValidations
  let!(:stale) { create(:member).tap { |member| member.update_columns(latitude: 51.5, longitude: -0.1) } } # rubocop:disable Rails/SkipsModelValidations
  let!(:missing) { create(:member).tap { |member| member.update_columns(latitude: 35.7, longitude: 139.7) } } # rubocop:disable Rails/SkipsModelValidations
  let!(:unlocated) { create(:member, location: nil) }

  before do
    create(:climate_month, latitude: -41.25, longitude: 174.75)
    create(:climate_month, latitude: 51.5, longitude: 0.0, updated_at: 2.months.ago)
  end

  it { expect(coverage.counts).to eq('covered' => 1, 'stale' => 1, 'missing' => 1, 'unlocated' => 1) }
  it { expect(coverage.ids('covered')).to eq [covered.id] }
  it { expect(coverage.ids('missing')).to eq [missing.id] }
  it { expect(coverage.ids('unlocated')).to eq [unlocated.id] }
  it { expect(coverage.ids('stale')).to eq [stale.id] }
  it { expect(coverage.status_of(covered.id)).to eq 'covered' }
  it { expect(coverage.fetched_on(51.5, -0.1)).to eq 2.months.ago.to_date }
  it { expect(coverage.fetched_on(35.7, 139.7)).to be_nil }
end
