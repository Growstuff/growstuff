# frozen_string_literal: true

require 'rails_helper'

describe Plant do
  let(:owner)    { create(:member) }
  let(:garden)   { create(:garden, owner:, grid_columns: 4, grid_rows: 3) }
  let(:planting) { create(:planting, garden:, owner:, quantity: 1).tap { garden.prepare_layout } }

  def plant(**attrs)
    described_class.new(planting:, **attrs)
  end

  describe 'its position on the bed' do
    it 'is unplaced until it has both a column and a row' do
      expect(plant).not_to be_placed
      expect(plant(bed_x: 1.5, bed_y: 0.5)).to be_placed
    end

    it 'needs both a column and a row, or neither' do
      expect(plant(bed_x: 1)).not_to be_valid
      expect(plant(bed_y: 1)).not_to be_valid
      expect(plant(bed_x: nil, bed_y: nil)).to be_valid
    end

    # A position is the plant's centre, and can be anywhere, not just in a cell.
    it 'can sit anywhere on the bed, edges included' do
      expect(plant(bed_x: 2.37, bed_y: 1.81)).to be_valid
      expect(plant(bed_x: 0, bed_y: 0)).to be_valid
      expect(plant(bed_x: 4, bed_y: 3)).to be_valid
    end

    it 'cannot sit off the bed' do
      expect(plant(bed_x: 4.1, bed_y: 1)).not_to be_valid
      expect(plant(bed_x: 1, bed_y: 3.1)).not_to be_valid
      expect(plant(bed_x: -0.5, bed_y: 1)).not_to be_valid
    end

    it 'finds placed, unplaced, and off-grid plants' do
      on_bed = planting.plants.first.tap { |p| p.update!(bed_x: 3.5, bed_y: 2.5) }
      waiting = planting.plants.create!

      expect(described_class.placed).to include(on_bed)
      expect(described_class.placed).not_to include(waiting)
      expect(described_class.unplaced).to include(waiting)
      expect(described_class.outside_grid(3, 3)).to include(on_bed)
      expect(described_class.outside_grid(4, 3)).not_to include(on_bed)
    end
  end

  describe 'its size' do
    it 'follows its crop until it is resized' do
      expect(plant(diameter: nil)).to be_valid
    end

    it 'can be anything from a sliver up to the cap' do
      expect(plant(diameter: 0.25)).to be_valid
      expect(plant(diameter: described_class::MAX_DIAMETER)).to be_valid
      expect(plant(diameter: 0)).not_to be_valid
      expect(plant(diameter: described_class::MAX_DIAMETER + 0.1)).not_to be_valid
    end
  end

  describe 'how many a planting can have' do
    it 'stops at the cap, which applies however the plant is made' do
      now = Time.current
      rows = Array.new(Planting::MAX_PLANTS - planting.plants.count) do
        { planting_id: planting.id, created_at: now, updated_at: now }
      end
      described_class.insert_all(rows) # rubocop:disable Rails/SkipsModelValidations

      extra = plant
      expect(extra).not_to be_valid
      expect(extra.errors[:base]).to include("a planting can have at most #{Planting::MAX_PLANTS} plants on the layout")
    end

    it "doesn't count against the cap when an existing plant is saved" do
      existing = planting.plants.first
      expect(existing.update(bed_x: 1, bed_y: 1)).to be true
    end
  end

  it 'reaches its garden, crop and owner through its planting' do
    record = plant
    expect([record.garden, record.crop, record.owner]).to eq [garden, planting.crop, owner]
  end
end
