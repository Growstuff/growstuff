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
  end

  describe "PATCH /members/:member_slug/gardens/:slug/layout" do
    let(:owner)        { create(:member) }
    let(:someone_else) { create(:member) }
    let(:garden)       { create(:garden, owner: owner, grid_columns: 4, grid_rows: 3) }
    let(:crop)         { create(:crop) }
    let!(:lettuce)     { create(:planting, garden: garden, owner: owner, crop: crop) }
    let!(:tomato)      { create(:planting, garden: garden, owner: owner, crop: crop) }

    def place(placements)
      patch layout_member_garden_path(garden.owner, garden),
            params: { placements: placements }, as: :json
    end

    it "places plantings on the grid" do
      sign_in owner
      place([{ planting_id: lettuce.id, bed_x: 0, bed_y: 0 },
             { planting_id: tomato.id, bed_x: 2, bed_y: 1, bed_width: 2, bed_height: 2 }])

      expect(response).to have_http_status(:ok)
      expect(lettuce.reload.bed_x).to eq 0
      expect(tomato.reload).to have_attributes(bed_x: 2, bed_y: 1, bed_width: 2, bed_height: 2)
      expect(response.parsed_body['placed'].length).to eq 2
    end

    it "takes a planting off the grid when it is left out of the placements" do
      lettuce.update!(bed_x: 1, bed_y: 1)
      sign_in owner
      place([])

      expect(response).to have_http_status(:ok)
      expect(lettuce.reload.bed_x).to be_nil
    end

    # The whole point of clearing every placement before applying the new ones.
    it "lets two plantings swap cells in one save" do
      lettuce.update!(bed_x: 0, bed_y: 0)
      tomato.update!(bed_x: 1, bed_y: 0)
      sign_in owner
      place([{ planting_id: lettuce.id, bed_x: 1, bed_y: 0 },
             { planting_id: tomato.id, bed_x: 0, bed_y: 0 }])

      expect(response).to have_http_status(:ok)
      expect(lettuce.reload.bed_x).to eq 1
      expect(tomato.reload.bed_x).to eq 0
    end

    # Every drag sends the whole arrangement, so most placements repeat a
    # position the plant already has. Clearing the rows and then re-assigning
    # the same value to records loaded beforehand leaves them unchanged as far
    # as dirty tracking goes, so the save does nothing and they silently drop
    # off the bed: everything but the plant just dragged disappears.
    it "keeps plants that are sent back at the position they already had" do
      lettuce.update!(bed_x: 0, bed_y: 0)
      tomato.update!(bed_x: 1, bed_y: 0)
      sign_in owner
      place([{ planting_id: lettuce.id, bed_x: 0, bed_y: 0 },
             { planting_id: tomato.id, bed_x: 1, bed_y: 0 },
             { planting_id: third.id, bed_x: 2, bed_y: 2 }])

      expect(response).to have_http_status(:ok)
      expect(lettuce.reload.bed_x).to eq 0
      expect(tomato.reload.bed_x).to eq 1
      expect(third.reload.bed_x).to eq 2
    end

    it "rolls the whole bed back when one placement is invalid" do
      lettuce.update!(bed_x: 0, bed_y: 0)
      sign_in owner
      place([{ planting_id: lettuce.id, bed_x: 2, bed_y: 2 },
             { planting_id: tomato.id, bed_x: 9, bed_y: 9 }])

      expect(response).to have_http_status(:unprocessable_entity)
      expect(lettuce.reload.bed_x).to eq 0
      expect(tomato.reload.bed_x).to be_nil
    end

    it "refuses a planting that is not in this garden" do
      other = create(:planting, owner: owner, crop: crop)
      sign_in owner
      place([{ planting_id: other.id, bed_x: 0, bed_y: 0 }])

      expect(response).to have_http_status(:unprocessable_entity)
      expect(other.reload.bed_x).to be_nil
    end

    # Development raises on unpermitted parameters and test only logs, so this
    # turns the check on to cover what the browser actually hits: the route's
    # :member_slug and :slug, plus the empty :garden that wrap_parameters adds
    # to JSON requests.
    it "does not treat the route and wrapped params as unpermitted" do
      original = ActionController::Parameters.action_on_unpermitted_parameters
      ActionController::Parameters.action_on_unpermitted_parameters = :raise
      sign_in owner
      place([{ planting_id: lettuce.id, bed_x: 0, bed_y: 0 }])

      expect(response).to have_http_status(:ok)
      expect(lettuce.reload.bed_x).to eq 0
    ensure
      ActionController::Parameters.action_on_unpermitted_parameters = original
    end

    it "does not let someone else rearrange the bed" do
      sign_in someone_else
      place([{ planting_id: lettuce.id, bed_x: 0, bed_y: 0 }])

      expect(response).to have_http_status(:forbidden)
      expect(lettuce.reload.bed_x).to be_nil
    end

    it "lets a collaborator rearrange the bed" do
      collaborator = create(:member)
      create(:garden_collaborator, garden: garden, member: collaborator)
      sign_in collaborator
      place([{ planting_id: lettuce.id, bed_x: 0, bed_y: 0 }])

      expect(response).to have_http_status(:ok)
      expect(lettuce.reload.bed_x).to eq 0
    end
  end
end
