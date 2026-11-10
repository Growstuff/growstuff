# frozen_string_literal: true

require 'rails_helper'

describe MemberClimateCoverage do
  subject(:coverage) { described_class.new(Member.all) }

  let(:wellington) { { latitude: -41.3, longitude: 174.8 } }
  let(:london) { { latitude: 51.5, longitude: -0.1 } }
  let(:own_covered) { create(:member).tap { |member| member.update_columns(wellington) } } # rubocop:disable Rails/SkipsModelValidations
  let(:garden_covered) { create(:member).tap { |member| member.gardens.first.update_columns(wellington) } } # rubocop:disable Rails/SkipsModelValidations
  let(:own_missing) { create(:member).tap { |member| member.update_columns(latitude: 35.7, longitude: 139.7) } } # rubocop:disable Rails/SkipsModelValidations
  let(:nowhere) { create(:member, location: nil) }
  let(:garden_stale) { create(:member).tap { |member| member.gardens.first.update_columns(london) } } # rubocop:disable Rails/SkipsModelValidations

  before do
    create(:climate_month, latitude: -41.25, longitude: 174.75)
    create(:climate_month, latitude: 51.5, longitude: 0.0, updated_at: 2.months.ago)
    [own_covered, garden_covered, own_missing, nowhere, garden_stale]
  end

  it { expect(coverage.counts).to eq('covered' => 2, 'stale' => 1, 'missing' => 1, 'unlocated' => 1) }
  it { expect(coverage.status_of(garden_stale.id)).to eq 'stale' }
  it { expect(coverage.gardens(garden_stale.id)).to eq [1, 0, 1] }
  it { expect(coverage.status_of(garden_covered.id)).to eq 'covered' }
  it { expect(coverage.own_status(garden_covered.id)).to eq 'unlocated' }
  it { expect(coverage.gardens(garden_covered.id)).to eq [1, 1, 0] }
  it { expect(coverage.gardens(nowhere.id)).to eq [0, 0, 0] }
end
