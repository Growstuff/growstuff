require 'rails_helper'

describe PhotoAssociationsController do
  login_member

  describe "destroy" do
    let(:valid_params) do
      {
        id: harvest.id,
        type: 'harvest',
        photo_id: photo.id
      }
    end

    before { photo.harvests << harvest }

    describe "my harvest my photo" do
      let(:harvest) { FactoryBot.create :harvest, owner: member }
      let(:photo) { FactoryBot.create :photo, owner: member }

      it "removes link" do
        expect { delete :destroy, valid_params }.to change { photo.harvests.count }.by(-1)
      end
    end

    describe "another member's harvest from another member's photo" do
      let(:harvest) { FactoryBot.create :harvest }
      let(:photo) { FactoryBot.create :photo }

      it do
        expect do
          begin
            delete :destroy, valid_params
          rescue StandardError
            nil
          end
        end.not_to change(photo.harvests, :count)
      end
      it { expect { delete :destroy, valid_params }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end
