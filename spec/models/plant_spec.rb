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
    it('is unplaced without a column and a row') { expect(plant).not_to be_placed }
    it('is placed with both a column and a row') { expect(plant(bed_x: 1.5, bed_y: 0.5)).to be_placed }

    it('is invalid with a column only') { expect(plant(bed_x: 1)).not_to be_valid }
    it('is invalid with a row only') { expect(plant(bed_y: 1)).not_to be_valid }
    it('is valid with neither') { expect(plant(bed_x: nil, bed_y: nil)).to be_valid }

    # A position is the plant's centre, and can be anywhere, not just in a cell.
    [[2.37, 1.81], [0, 0], [4, 3]].each do |x, y|
      it "can sit at #{x}, #{y} on the bed, edges included" do
        expect(plant(bed_x: x, bed_y: y)).to be_valid
      end
    end

    [[4.1, 1], [1, 3.1], [-0.5, 1]].each do |x, y|
      it "cannot sit at #{x}, #{y}, off the bed" do
        expect(plant(bed_x: x, bed_y: y)).not_to be_valid
      end
    end

    context 'with a placed plant and a waiting one' do
      let!(:on_bed) { planting.plants.first.tap { |p| p.update!(bed_x: 3.5, bed_y: 2.5) } }
      let!(:waiting) { planting.plants.create! }

      it('finds the placed plant as placed') { expect(described_class.placed).to include(on_bed) }
      it('leaves the waiting plant out of placed') { expect(described_class.placed).not_to include(waiting) }
      it('finds the waiting plant as unplaced') { expect(described_class.unplaced).to include(waiting) }
      it('finds a plant outside a smaller grid') { expect(described_class.outside_grid(3, 3)).to include(on_bed) }
      it('leaves a plant inside a big enough grid') { expect(described_class.outside_grid(4, 3)).not_to include(on_bed) }
    end
  end

  describe 'its size' do
    it 'follows its crop until it is resized' do
      expect(plant(diameter: nil)).to be_valid
    end

    it('can be a sliver') { expect(plant(diameter: 0.25)).to be_valid }
    it('can be as big as the cap') { expect(plant(diameter: described_class::MAX_DIAMETER)).to be_valid }
    it('cannot be nothing') { expect(plant(diameter: 0)).not_to be_valid }
    it('cannot be over the cap') { expect(plant(diameter: described_class::MAX_DIAMETER + 0.1)).not_to be_valid }
  end

  describe 'how many a planting can have' do
    context 'when the planting is at the cap, however its plants were made' do
      subject(:extra) { plant }

      before do
        now = Time.current
        rows = Array.new(Planting::MAX_PLANTS - planting.plants.count) do
          { planting_id: planting.id, created_at: now, updated_at: now }
        end
        described_class.insert_all(rows) # rubocop:disable Rails/SkipsModelValidations
        extra.validate
      end

      it { is_expected.not_to be_valid }

      it 'explains the cap' do
        expect(extra.errors[:base]).to include("a planting can have at most #{Planting::MAX_PLANTS} plants on the layout")
      end
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
