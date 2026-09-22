# frozen_string_literal: true

require 'rails_helper'

describe GardenLayoutSerializer do
  subject(:layout) { described_class.new(garden, editable: true, resizable: true).as_json }

  let(:owner)   { create(:member) }
  let(:garden)  { create(:garden, owner:, name: 'Sunny bed', grid_columns: 4, grid_rows: 3) }
  let(:lettuce) { create(:crop, name: 'lettuce') }

  def planting_json(planting)
    layout[:plantings].find { |json| json[:id] == planting.id }
  end

  it 'describes the bed, and where to save and reload it' do
    expect(layout[:garden]).to include(name: 'Sunny bed', grid_columns: 4, grid_rows: 3,
                                       url: "/gardens/#{garden.slug}")
    expect(layout[:save_url]).to eq("/members/#{owner.slug}/gardens/#{garden.slug}/layout")
    expect(layout[:layout_url]).to eq("/members/#{owner.slug}/gardens/#{garden.slug}/layout.json")
    expect(layout).to include(max_grid_size: Garden::MAX_GRID_SIZE, max_diameter: Plant::MAX_DIAMETER)
  end

  it "says what the viewer may do, and doesn't offer planting into an inactive garden" do
    expect(layout).to include(editable: true, resizable: true, plantable: true)

    viewer = described_class.new(garden, editable: false).as_json
    expect(viewer).to include(editable: false, resizable: false, plantable: false)

    garden.update!(active: false)
    expect(described_class.new(garden, editable: true, resizable: true).as_json[:plantable]).to be false
  end

  it 'gives each planting its crop, icon, and every one of its plants, placed or not' do
    planting = create(:planting, garden:, owner:, crop: lettuce, quantity: 2)
    garden.prepare_layout
    placed, waiting = planting.plants.order(:id).to_a
    placed.update!(bed_x: 1.5, bed_y: 2.25, diameter: 0.75)

    json = planting_json(planting)
    expect(json).to include(crop_name: 'lettuce', icon_url: "/crops/#{lettuce.slug}.svg",
                            quantity: 2, planted_at: planting.planted_at, default_diameter: 1)
    expect(json[:plants]).to eq [
      { id: placed.id, bed_x: 1.5, bed_y: 2.25, diameter: 0.75 },
      { id: waiting.id, bed_x: nil, bed_y: nil, diameter: nil }
    ]
  end

  it "draws a crop's plants at its default size, or its parent crop's" do
    lettuce.update!(default_diameter: 0.5)
    cos = create(:crop, name: 'cos lettuce', parent: lettuce)
    own = create(:planting, garden:, owner:, crop: lettuce)
    inherited = create(:planting, garden:, owner:, crop: cos)

    expect(planting_json(own)[:default_diameter]).to eq 0.5
    expect(planting_json(inherited)[:default_diameter]).to eq 0.5
  end

  # So the page can colour plantings that would otherwise look alike.
  it 'says which plantings are drawn with the same icon' do
    iconless = create(:crop, name: 'kale')
    first = create(:planting, garden:, owner:, crop: iconless)
    second = create(:planting, garden:, owner:, crop: lettuce)
    lettuce.update!(openfarm_data: { 'attributes' => { 'svg_icon' => '<svg>lettuce</svg>' } })
    third = create(:planting, garden:, owner:, crop: iconless)

    keys = [first, second, third].map { |planting| planting_json(planting)[:icon_key] }
    expect(keys[0]).to eq keys[2]
    expect(keys[0]).not_to eq keys[1]
  end

  it 'leaves out plantings that are no longer growing' do
    create(:planting, garden:, owner:, crop: lettuce, finished: true, finished_at: 1.day.ago)
    create(:planting, garden:, owner:, crop: lettuce, failed: true)

    expect(layout[:plantings]).to be_empty
  end

  # By date alone, plantings made the same day came back in no fixed order, and
  # the sidebar reshuffled whenever a save touched them.
  it 'lists plantings by crop name, then oldest first, and in the same order every time' do
    basil = create(:crop, name: 'basil')
    zucchini = create(:crop, name: 'Zucchini')
    later = create(:planting, garden:, owner:, crop: lettuce, planted_at: 2.days.ago)
    earlier = create(:planting, garden:, owner:, crop: lettuce, planted_at: 9.days.ago)
    same_day = [create(:planting, garden:, owner:, crop: basil, planted_at: 3.days.ago),
                create(:planting, garden:, owner:, crop: zucchini, planted_at: 3.days.ago)]

    expect(layout[:plantings].pluck(:id)).to eq [same_day.first.id, earlier.id, later.id, same_day.last.id]
  end
end
