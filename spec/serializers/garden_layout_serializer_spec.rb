# frozen_string_literal: true

require 'rails_helper'

describe GardenLayoutSerializer do
  let(:owner)  { create(:member) }
  let(:garden) { create(:garden, owner:, name: 'Sunny bed', grid_columns: 4, grid_rows: 3) }
  let(:crop)   { create(:crop, name: 'lettuce') }

  subject(:layout) { described_class.new(garden, editable: true).as_json }

  it 'describes the bed and where to save it' do
    expect(layout[:garden]).to include(name: 'Sunny bed', grid_columns: 4, grid_rows: 3)
    expect(layout[:save_url]).to eq("/members/#{owner.slug}/gardens/#{garden.slug}/layout")
    expect(layout[:editable]).to be true
    expect(layout[:max_grid_size]).to eq Garden::MAX_GRID_SIZE
  end

  it 'splits the plantings into those on the grid and those still to place' do
    placed = create(:planting, garden:, owner:, crop:, bed_x: 1, bed_y: 2, bed_width: 2)
    waiting = create(:planting, garden:, owner:, crop:)

    expect(layout[:placed].pluck(:id)).to eq [placed.id]
    expect(layout[:placed].first).to include(bed_x: 1, bed_y: 2, bed_width: 2, bed_height: 1, crop_name: 'lettuce')
    expect(layout[:placed].first).to have_key(:quantity)
    expect(layout[:unplaced].pluck(:id)).to eq [waiting.id]
    expect(layout[:unplaced].first).to include(bed_x: nil, bed_y: nil)
  end

  it 'leaves out plantings that are no longer growing' do
    create(:planting, garden:, owner:, crop:, bed_x: 0, bed_y: 0, finished: true)
    create(:planting, garden:, owner:, crop:, bed_x: 1, bed_y: 0, failed: true)

    expect(layout[:placed]).to be_empty
    expect(layout[:unplaced]).to be_empty
  end

  it 'passes the number of plants through, so the map can draw one circle each' do
    create(:planting, garden:, owner:, crop:, bed_x: 0, bed_y: 0, quantity: 10)
    create(:planting, garden:, owner:, crop:, bed_x: 1, bed_y: 0, quantity: nil)

    expect(layout[:placed].map { |planting| planting[:quantity] }).to eq [10, nil]
  end

  it 'says when the viewer may not rearrange it' do
    expect(described_class.new(garden, editable: false).as_json[:editable]).to be false
  end
end
