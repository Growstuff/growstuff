# frozen_string_literal: true

require 'rails_helper'

describe PhotoAssociationsController do
  login_member

  describe "destroy" do
    let(:valid_params) do
      {
        id:       harvest.id,
        type:     'harvest',
        photo_id: photo.id
      }
    end

    before { photo.harvests << harvest }

    describe "my harvest my photo" do
      let(:harvest) { FactoryBot.create :harvest, owner: member }
      let(:photo)   { FactoryBot.create :photo, owner: member   }

      it "removes link" do
        expect { delete :destroy, params: valid_params }.to change { photo.harvests.count }.by(-1)
      end
    end

    describe "another member's harvest from another member's photo" do
      let(:harvest) { FactoryBot.create :harvest, owner: photo.owner }
      let(:photo) { FactoryBot.create :photo }

      it do
        expect do
          delete :destroy, params: valid_params
        rescue StandardError
          nil
        end.not_to change(photo.harvests, :count)
      end

      it do
        delete :destroy, params: valid_params
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
