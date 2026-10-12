# frozen_string_literal: true

require 'rails_helper'

describe PhotoAssociationsController do
  login_member

  describe "destroy" do
    describe "harvest photo association" do
      let(:valid_params) do
        {
          id:       harvest.id,
          type:     'harvest',
          photo_id: photo.id
        }
      end

      describe "my harvest my photo" do
        let(:harvest) { create(:harvest, owner: member) }
        let(:photo)   { create(:photo, owner: member)   }

        before { PhotoAssociation.create!(photo: photo, photographable: harvest) }

        it "removes link" do
          expect { delete :destroy, params: valid_params }.to change { photo.harvests.count }.by(-1)
        end
      end

      describe "another member's harvest from another member's photo" do
        let(:harvest) { create(:harvest) }
        let(:photo)   { create(:photo, owner: harvest.owner) }

        before { PhotoAssociation.create!(photo: photo, photographable: harvest) }

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

    describe "crop photo association" do
      let(:crop)  { create(:crop) }
      let(:photo) { create(:photo, owner: member) }

      before { PhotoAssociation.create!(photo: photo, photographable: crop) }

      it "removes link to crop when photo owner deletes association" do
        expect do
          delete :destroy, params: { id: crop.id, type: 'crop', photo_id: photo.id }
        end.to change { crop.photos.count }.by(-1)
      end
    end

    describe "planting photo association" do
      let(:planting) { create(:planting, owner: member) }
      let(:photo)    { create(:photo, owner: member) }

      before { PhotoAssociation.create!(photo: photo, photographable: planting) }

      it "removes link to planting when planting owner deletes association" do
        expect do
          delete :destroy, params: { id: planting.id, type: 'planting', photo_id: photo.id }
        end.to change { photo.plantings.count }.by(-1)
      end
    end

    describe "invalid parameters" do
      let(:photo) { create(:photo, owner: member) }

      it "returns 404 for unsupported item type" do
        delete :destroy, params: { id: 1, type: 'invalid_type', photo_id: photo.id }
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for non-existent item id" do
        delete :destroy, params: { id: 999_999, type: 'crop', photo_id: photo.id }
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for non-existent photo id" do
        crop = create(:crop)
        delete :destroy, params: { id: crop.id, type: 'crop', photo_id: 999_999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
