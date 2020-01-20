# frozen_string_literal: true

require 'rails_helper'

describe PhotosController, :search do
  login_member

  describe 'GET index' do
    describe 'all photos' do
      let!(:photo) { FactoryBot.create :photo, :reindex }

      before do
        Photo.reindex
        get :index
      end

      it "finds photos" do
        expect(assigns(:photos).count).to eq 1
        expect(assigns(:photos).first.id).to eq photo.id
      end
    end

    describe '#index crop photos' do
      let!(:photo)      { FactoryBot.create :photo, :reindex, owner: member, title: 'no assocations photo' }
      let!(:crop_photo) { FactoryBot.create :photo, :reindex, owner: member, title: 'photos of planting'   }
      let!(:planting)   { FactoryBot.create :planting, :reindex, crop: crop, owner: member                 }
      let!(:crop)       { FactoryBot.create :crop, :reindex                                                }

      before do
        planting.photos << crop_photo
        Photo.reindex
        get :index, params: { crop_slug: crop.to_param }
      end

      describe "find photos by crop" do
        it "has indexed the photos of this crop" do
          expect(Photo.search).to include crop_photo
        end
        it "assigns crop" do
          expect(assigns(:crop)).to eq crop
        end

        it { expect(assigns(:photos).size).to eq 1 }
        it { expect(assigns(:photos).first.crops).to include crop.id }
        it { expect(assigns(:photos).first.id).to eq crop_photo.id }
      end
    end
  end

  describe "GET new" do
    let(:tomato)   { FactoryBot.create(:tomato)                                }
    let(:planting) { FactoryBot.create(:planting, crop: tomato, owner: member) }
    let(:garden)   { FactoryBot.create(:garden, owner: member)                 }
    let(:harvest)  { FactoryBot.create(:harvest, owner: member)                }
    let(:member)   { FactoryBot.create(:member)                                }
    let!(:auth)    { FactoryBot.create(:flickr_authentication, member: member) }

    before do
      sign_in member
      member.stub(:flickr_photos) { [[], 0] }
      member.stub(:flickr_sets) { { "foo" => "bar" } }
      controller.stub(:current_member) { member }
    end

    describe "planting photos" do
      before { get :new, params: { type: "planting", id: planting.id } }

      it { expect(assigns(:flickr_auth)).to be_an_instance_of(Authentication) }
      it { expect(assigns(:item)).to eq planting }
      it { expect(flash[:alert]).not_to be_present }
      it { expect(flash[:alert]).not_to be_present }
    end

    describe "harvest photos" do
      before { get :new, params: { type: "harvest", id: harvest.id } }

      it { expect(assigns(:item)).to eq harvest }
      it { expect(flash[:alert]).not_to be_present }
    end

    describe "garden photos" do
      before { get :new, params: { type: "garden", id: garden.id } }

      it { expect(assigns(:item)).to eq garden }
      it { expect(flash[:alert]).not_to be_present }
    end
  end

  describe "POST create" do
    before do
      Photo.any_instance.stub(:flickr_metadata).and_return(title:         "A Heartbreaking work of staggering genius",
                                                           license_name:  "CC-BY",
                                                           license_url:   "http://example.com/aybpl",
                                                           thumbnail_url: "http://example.com/thumb.jpg",
                                                           fullsize_url:  "http://example.com/full.jpg",
                                                           link_url:      "http://example.com")
    end

    let(:member)   { FactoryBot.create(:member)                                  }
    let(:garden)   { FactoryBot.create(:garden, owner: member)                   }
    let(:planting) { FactoryBot.create(:planting, garden: garden, owner: member) }
    let(:harvest)  { FactoryBot.create(:harvest, owner: member)                  }
    let(:photo)    { FactoryBot.create(:photo, owner: member)                    }

    describe "with valid params" do
      before { controller.stub(:current_member) { member } }

      describe "attaches the photo to a planting" do
        before do
          post :create, params: {
            photo: { source_id: photo.source_id, source: 'flickr' },
            type: "planting", id: planting.id
          }
        end
        it { expect(flash[:alert]).not_to be_present }
        it { expect(Photo.last.plantings.first).to eq planting }
      end

      describe "doesn't attach a photo to a planting twice" do
        before do
          post :create, params: {
            photo: { source_id: photo.source_id, source: 'flickr' }, type: "planting", id: planting.id
          }
          post :create, params: {
            photo: { source_id: photo.source_id, source: 'flickr' }, type: "planting", id: planting.id
          }
        end

        it { expect(flash[:alert]).not_to be_present }
        it { expect(Photo.last.plantings.size).to eq 1 }
      end

      it "attaches the photo to a harvest" do
        post :create, params: { photo: { source_id: photo.source_id, source: 'flickr' }, type: "harvest", id: harvest.id }
        expect(flash[:alert]).not_to be_present
        Photo.last.harvests.first.should eq harvest
      end

      describe "doesn't attach a photo to a harvest twice" do
        before do
          post :create, params: {
            photo: { source_id: photo.source_id, source: 'flickr' }, type: "harvest", id: harvest.id
          }
          post :create, params: {
            photo: { source_id: photo.source_id, source: 'flickr' }, type: "harvest", id: harvest.id
          }
        end
        it { expect(flash[:alert]).not_to be_present }
        it { expect(Photo.last.harvests.size).to eq 1 }
      end

      it "doesn't attach photo to a comment" do
        comment = FactoryBot.create(:comment)
        expect do
          post :create, params: {
            photo: { source_id: photo.source_id, source: 'flickr' }, type: "comment", id: comment.id
          }
        end.to raise_error 'Photos not supported'
      end
    end

    describe "for the second time" do
      let(:planting) { FactoryBot.create :planting, owner: member }
      let(:valid_params) { { photo: { source_id: 1 }, id: planting.id, type: 'planting' } }

      it "does not add a photo twice" do
        expect { post :create, params: valid_params }.to change(Photo, :count).by(1)
        expect { post :create, params: valid_params }.not_to change(Photo, :count)
      end
    end

    describe "with matching owners" do
      before { controller.stub(:current_member) { member } }

      describe "creates the planting/photo link" do
        let(:planting) { FactoryBot.create(:planting, garden: garden, owner: member) }
        let(:photo) { FactoryBot.create(:photo, owner: member) }
        before { post :create, params: { photo: { source_id: photo.source_id, source: 'flickr' }, type: "planting", id: planting.id } }
        it { expect(flash[:alert]).not_to be_present }
        it { expect(Photo.last.plantings.first).to eq planting }
      end

      describe "creates the harvest/photo link" do
        before do
          post :create, params: { photo: { source_id: photo.source_id, source: 'flickr' }, type: "harvest", id: harvest.id }
        end

        it { expect(flash[:alert]).not_to be_present }
        it { expect(Photo.last.harvests.first).to eq harvest }
      end
    end

    describe "with mismatched owners" do
      let(:photo) { FactoryBot.create(:photo) }

      it "does not create the planting/photo link" do
        # members will be auto-created, and different
        another_planting = FactoryBot.create(:planting)
        expect do
          post :create, params: {
            photo: { source_id: photo.source_id, source: 'flickr' },
            type: "planting", id: another_planting.id
          }
        end.to raise_error(ActiveRecord::RecordInvalid)
        expect(Photo.last.plantings.first).not_to eq another_planting
      end

      it "does not create the harvest/photo link" do
        # members will be auto-created, and different
        another_harvest = FactoryBot.create(:harvest)
        expect do
          post :create, params: {
            photo: { source_id: photo.source_id, source: 'flickr' }, type: "harvest", id: another_harvest.id
          }
        end.to raise_error(ActiveRecord::RecordInvalid)
        expect(Photo.last.harvests.first).not_to eq another_harvest
      end
    end
  end
end
