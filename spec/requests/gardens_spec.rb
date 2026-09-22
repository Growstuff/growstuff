# frozen_string_literal: true

require 'rails_helper'

describe "Gardens" do
  describe "GET /gardens" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get gardens_path
      response.status.should be(200)
    end
  end

  describe "GET /members/:member_slug/gardens/:slug/layout" do
    let(:owner)   { create(:member) }
    let!(:garden) { create(:garden, owner: owner, name: 'Sunny Bed') }

    it "shows the garden's layout to anyone, without signing in" do
      get layout_member_garden_path(owner, garden)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Sunny Bed')
    end

    it "shows the layout to the garden's owner" do
      sign_in owner
      get layout_member_garden_path(owner, garden)

      expect(response).to have_http_status(:ok)
    end

    it "404s for a garden that doesn't exist" do
      get layout_member_garden_path(owner, 'no-such-garden')

      expect(response).to have_http_status(:not_found)
    end

    # Plants are only made once someone comes to use the layout.
    it "gives the plantings their plants when someone who can arrange the bed opens it" do
      planting = create(:planting, garden:, owner:, quantity: 3)
      sign_in owner
      get layout_member_garden_path(owner, garden)

      expect(planting.plants.count).to eq 3
    end

    it "doesn't make any plants for someone who is only looking" do
      planting = create(:planting, garden:, owner:, quantity: 3)
      get layout_member_garden_path(owner, garden)

      expect(planting.plants).to be_empty
    end
  end

  describe "GET /members/:member_slug/gardens/:slug/layout.json" do
    let(:owner)   { create(:member) }
    let!(:garden) { create(:garden, owner:) }

    # The page re-reads this after planting something new from its dialog, and
    # the new planting needs its plants then.
    it "gives the layout's data, for the page to reload itself" do
      create(:planting, garden:, owner:, quantity: 2)
      sign_in owner
      get layout_member_garden_path(owner, garden, format: :json)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['plantings'].first['plants'].length).to eq 2
    end
  end

  describe "PATCH /members/:member_slug/gardens/:slug/layout" do
    let(:owner)        { create(:member) }
    let(:someone_else) { create(:member) }
    let(:garden)       { create(:garden, owner:, grid_columns: 4, grid_rows: 3) }
    let(:crop)         { create(:crop) }
    let!(:lettuce)     { create(:planting, garden:, owner:, crop:, quantity: 2) }
    let!(:tomato)      { create(:planting, garden:, owner:, crop:, quantity: 1) }
    let(:lettuce_plants) { lettuce.plants.order(:id).to_a }
    let(:tomato_plant)   { tomato.plants.first }

    before { garden.prepare_layout }

    # A planting in someone else's garden, laid out there.
    def planted_elsewhere(**)
      create(:planting, owner:, crop:, **).tap { |planting| planting.garden.prepare_layout }
    end

    def save_layout(placements = [], composted: [])
      patch layout_member_garden_path(garden.owner, garden),
            params: { placements:, composted: }, as: :json
    end

    def at(plant, col, row, diameter: nil)
      { plant_id: plant.id, bed_x: col, bed_y: row, diameter: }
    end

    describe 'arranging' do
      before { sign_in owner }

      it 'puts plants where they are dropped, anywhere on the bed' do
        save_layout([at(lettuce_plants.first, 0.5, 0.5), at(tomato_plant, 2.37, 1.81)])

        expect(response).to have_http_status(:ok)
        expect(tomato_plant.reload).to have_attributes(bed_x: 2.37, bed_y: 1.81)
        expect(response.parsed_body['plantings'].sum { |planting| planting['plants'].count { |plant| plant['bed_x'] } }).to eq 2
      end

      it 'takes a plant off the bed when the arrangement leaves it out' do
        tomato_plant.update!(bed_x: 1, bed_y: 1)
        save_layout([])

        expect(response).to have_http_status(:ok)
        expect(tomato_plant.reload.bed_x).to be_nil
        expect(tomato.reload.plants.count).to eq 1
      end

      # Every drag sends the whole arrangement, so most placements repeat a
      # position the plant already has. Clearing the rows and then re-assigning
      # the same value to records loaded beforehand leaves them unchanged as far
      # as dirty tracking goes, so the save does nothing and they silently drop
      # off the bed: everything but the plant just dragged disappears.
      it 'keeps plants that are sent back at the position they already had' do
        lettuce_plants.first.update!(bed_x: 0.5, bed_y: 0.5)
        tomato_plant.update!(bed_x: 1.5, bed_y: 0.5)
        save_layout([at(lettuce_plants.first, 0.5, 0.5), at(tomato_plant, 1.5, 0.5), at(lettuce_plants.last, 2.5, 2.5)])

        expect(response).to have_http_status(:ok)
        expect([lettuce_plants.first, tomato_plant, lettuce_plants.last].map { |plant| plant.reload.bed_x }).to eq [0.5, 1.5, 2.5]
      end

      it 'saves a size given to a plant, and lets it follow its crop again' do
        save_layout([at(tomato_plant, 1, 1, diameter: 1.75)])
        expect(tomato_plant.reload.diameter).to eq 1.75

        save_layout([at(tomato_plant, 1, 1)])
        expect(tomato_plant.reload.diameter).to be_nil
      end

      it 'rolls the whole bed back when one placement is invalid' do
        tomato_plant.update!(bed_x: 1, bed_y: 1)
        save_layout([at(tomato_plant, 2, 2), at(lettuce_plants.first, 9, 9)])

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to be_present
        expect(tomato_plant.reload.bed_x).to eq 1
        expect(lettuce_plants.first.reload.bed_x).to be_nil
      end

      it 'refuses a size bigger than a plant can be drawn' do
        save_layout([at(tomato_plant, 1, 1, diameter: Plant::MAX_DIAMETER + 1)])

        expect(response).to have_http_status(:unprocessable_entity)
        expect(tomato_plant.reload.diameter).to be_nil
      end

      it 'refuses a plant from another garden' do
        stranger = planted_elsewhere(quantity: 1).plants.first
        save_layout([at(stranger, 0, 0)])

        expect(response).to have_http_status(:unprocessable_entity)
        expect(stranger.reload.bed_x).to be_nil
      end
    end

    describe 'dragging off a planting chip' do
      before { sign_in owner }

      def from_chip(planting, col, row)
        { planting_id: planting.id, bed_x: col, bed_y: row }
      end

      it 'uses a plant the planting already has before making another' do
        save_layout([from_chip(lettuce, 1, 1)])

        expect(response).to have_http_status(:ok)
        expect(lettuce.reload.plants.count).to eq 2
        expect(lettuce.plants.placed.count).to eq 1
        expect(lettuce.quantity).to eq 2
      end

      it 'makes another plant once they are all on the bed, and the planting grows' do
        tomato_plant.update!(bed_x: 0.5, bed_y: 0.5)
        save_layout([at(tomato_plant, 0.5, 0.5), from_chip(tomato, 2, 2)])

        expect(response).to have_http_status(:ok)
        expect(tomato.reload.plants.placed.count).to eq 2
        expect(tomato.quantity).to eq 2
      end

      it 'stops at the most plants a planting can have' do
        now = Time.current
        Plant.insert_all(Array.new(Planting::MAX_PLANTS - 1) { { planting_id: tomato.id, created_at: now, updated_at: now } }) # rubocop:disable Rails/SkipsModelValidations
        placed = tomato.plants.map.with_index { |plant, i| at(plant, (i % 4) + 0.5, (i / 40) + 0.5) }
        save_layout(placed + [from_chip(tomato, 1, 1)])

        expect(response).to have_http_status(:unprocessable_entity)
        expect(tomato.reload.plants.count).to eq Planting::MAX_PLANTS
      end

      it 'refuses a planting from another garden' do
        stranger = create(:planting, owner:, crop:)
        save_layout([from_chip(stranger, 1, 1)])

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'composting' do
      before { sign_in owner }

      it 'removes the plant, and the planting has one fewer' do
        plant = lettuce_plants.first.tap { |p| p.update!(bed_x: 1, bed_y: 1) }
        save_layout([], composted: [plant.id])

        expect(response).to have_http_status(:ok)
        expect(Plant.exists?(plant.id)).to be false
        expect(lettuce.reload.plants.count).to eq 1
        expect(lettuce.quantity).to eq 1
      end

      it "does not compost a plant from another garden, and deletes nothing" do
        stranger = planted_elsewhere(quantity: 1).plants.first
        save_layout([], composted: [stranger.id, tomato_plant.id])

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Plant.exists?(stranger.id)).to be true
        expect(Plant.exists?(tomato_plant.id)).to be true
      end
    end

    describe 'stepping stones, labels and rows' do
      before { sign_in owner }

      let(:features) do
        [{ id: 'a', kind: 'stone', x: 1.5, y: 1.5 },
         { id: 'b', kind: 'label', x: 2, y: 0.5, text: 'path' },
         { id: 'c', kind: 'row', x: 0.5, y: 2, x2: 3.5, y2: 2, text: 'carrots' }]
      end

      def save_features(list, placements: [])
        patch layout_member_garden_path(garden.owner, garden), params: { placements:, features: list }, as: :json
      end

      it 'saves them with the rest of the arrangement, and sends them back' do
        save_features(features)

        expect(response).to have_http_status(:ok)
        expect(garden.reload.layout_features.pluck('kind')).to eq %w(stone label row)
        expect(garden.layout_features.last).to include('x2' => 3.5, 'text' => 'carrots')
        expect(response.parsed_body['features'].length).to eq 3
      end

      it 'refuses the whole arrangement if one is off the bed' do
        save_features([{ id: 'a', kind: 'stone', x: 9, y: 1 }], placements: [at(tomato_plant, 1, 1)])

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']['features']).to eq ['A stone, label or row is off the bed']
        expect(garden.reload.layout_features).to be_empty
        expect(tomato_plant.reload.bed_x).to be_nil
      end

      it 'leaves them alone when a save does not mention them' do
        garden.update_column(:layout_features, [{ 'kind' => 'stone', 'x' => 1, 'y' => 1 }]) # rubocop:disable Rails/SkipsModelValidations
        save_layout([at(tomato_plant, 1, 1)])

        expect(garden.reload.layout_features.length).to eq 1
      end
    end

    # Development raises on unpermitted parameters and test only logs, so this
    # turns the check on to cover what the browser actually hits: the route's
    # :member_slug and :slug, plus the empty :garden that wrap_parameters adds
    # to JSON requests.
    it "does not treat the route and wrapped params as unpermitted" do
      original = ActionController::Parameters.action_on_unpermitted_parameters
      ActionController::Parameters.action_on_unpermitted_parameters = :raise
      sign_in owner
      patch layout_member_garden_path(garden.owner, garden),
            params: { placements: [at(tomato_plant, 1, 1, diameter: 2), { planting_id: lettuce.id, bed_x: 2, bed_y: 2 }],
                      composted:  [lettuce_plants.last.id],
                      features:   [{ id: 'a', kind: 'row', x: 0.5, y: 1, x2: 3, y2: 1, text: 'beans' }] },
            as:     :json

      expect(response).to have_http_status(:ok)
      expect(tomato_plant.reload).to have_attributes(bed_x: 1, diameter: 2)
    ensure
      ActionController::Parameters.action_on_unpermitted_parameters = original
    end

    describe 'who may' do
      it "doesn't let someone else rearrange the bed" do
        sign_in someone_else
        save_layout([at(tomato_plant, 1, 1)])

        expect(response).to have_http_status(:forbidden)
        expect(tomato_plant.reload.bed_x).to be_nil
      end

      it "doesn't let anyone signed out rearrange it" do
        save_layout([at(tomato_plant, 1, 1)])

        expect(response).to have_http_status(:unauthorized)
        expect(tomato_plant.reload.bed_x).to be_nil
      end

      it 'lets a collaborator rearrange the bed' do
        collaborator = create(:member)
        create(:garden_collaborator, garden:, member: collaborator)
        sign_in collaborator
        save_layout([at(tomato_plant, 1, 1)])

        expect(response).to have_http_status(:ok)
        expect(tomato_plant.reload.bed_x).to eq 1
      end
    end
  end

  # The layout page resizes the bed through the garden's own JSON update.
  describe "PATCH /gardens/:slug resizing the bed" do
    let(:owner)  { create(:member) }
    let(:garden) { create(:garden, owner:, grid_columns: 4, grid_rows: 3) }

    before { sign_in owner }

    def resize(columns, rows)
      patch garden_path(garden), params: { garden: { grid_columns: columns, grid_rows: rows } }, as: :json
    end

    it 'changes the size' do
      resize(6, 5)

      expect(response).to have_http_status(:ok)
      expect(garden.reload).to have_attributes(grid_columns: 6, grid_rows: 5)
    end

    it "does not shrink the bed out from under a plant" do
      create(:planting, garden:, owner:, quantity: 1)
      garden.prepare_layout
      garden.placed_or_owned_plants.first.update!(bed_x: 3.5, bed_y: 1)
      resize(2, 3)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(garden.reload.grid_columns).to eq 4
    end
  end
end
