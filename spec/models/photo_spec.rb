require 'spec_helper'

describe Photo do

  describe 'add/delete functionality' do
    let(:photo) { FactoryGirl.create(:photo) }
    let(:planting) { FactoryGirl.create(:planting) }
    let(:harvest) { FactoryGirl.create(:harvest) }

    context "adds photos" do
      it 'to a planting' do
        planting.photos << photo
        expect(planting.photos.count).to eq 1
        expect(planting.photos.first).to eq photo
      end

      it 'to a harvest' do
        harvest.photos << photo
        expect(harvest.photos.count).to eq 1
        expect(harvest.photos.first).to eq photo
      end
    end

    context "removing photos" do
      it 'from a planting' do
        planting.photos << photo
        photo.destroy
        expect(planting.photos.count).to eq 0
      end

      it 'from a harvest' do
        harvest.photos << photo
        photo.destroy
        expect(harvest.photos.count).to eq 0
      end

      it "automatically if unused" do
        photo.destroy_if_unused
        expect(lambda { photo.reload }).to raise_error ActiveRecord::RecordNotFound
      end

      it 'they are used by plantings but not harvests' do
        harvest.photos << photo
        planting.photos << photo
        harvest.destroy # photo is now used by harvest but not planting
        photo.destroy_if_unused
        expect(lambda { photo.reload }).not_to raise_error ActiveRecord::RecordNotFound
      end

      it 'they are used by harvests but not plantings' do
        harvest.photos << photo
        planting.photos << photo
        planting.destroy # photo is now used by harvest but not planting
        photo.destroy_if_unused
        expect(lambda { photo.reload }).not_to raise_error ActiveRecord::RecordNotFound
      end

      it 'they are no longer used by anything' do
        planting.photos << photo
        harvest.photos << photo
        expect(photo.plantings.size).to eq 1
        expect(photo.harvests.size).to eq 1

        planting.destroy # photo is still used by harvest
        photo.reload
        expect(photo.plantings.size).to eq 0
        expect(photo.harvests.size).to eq 1

        harvest.destroy # photo is now no longer used by anything
        photo.reload
        expect(photo.plantings.size).to eq 0
        expect(photo.harvests.size).to eq 0
        photo.destroy_if_unused
        expect(lambda { photo.reload }).to raise_error ActiveRecord::RecordNotFound
      end

      it 'does not occur when a photo is still in use' do
        planting.photos << photo
        harvest.photos << photo
        planting.destroy # photo is still used by the harvest
        expect(photo).to be_an_instance_of Photo
      end

    end # removing photos

  end # add/delete functionality

  describe 'flickr_metadata' do
    # Any further tests led to us MOCKING ALL THE THINGS
    # which was epistemologically unsatisfactory.
    # So we're just going to test that the method exists.
    it 'exists' do
      photo = Photo.new(:owner_id => 1)
      photo.should.respond_to? :flickr_metadata
    end
  end
end
