require 'rails_helper'

describe Photo do
  let(:photo)  { FactoryBot.create(:photo, owner: member) }
  let(:old_photo) { FactoryBot.create(:photo, owner: member, created_at: 1.year.ago, date_taken: 2.years.ago) }
  let(:member) { FactoryBot.create(:member) }

  it_behaves_like "it is likeable"

  describe 'add/delete functionality' do
    let(:planting) { FactoryBot.create(:planting, owner: member) }
    let(:seed) { FactoryBot.create(:seed, owner: member) }
    let(:harvest) { FactoryBot.create(:harvest, owner: member) }
    let(:post) { FactoryBot.create(:post, author: member) }
    let(:garden)  { FactoryBot.create(:garden, owner: member) }

    context "adds photos" do
      describe 'to a planting' do
        before { planting.photos << photo }

        it { expect(planting.photos.size).to eq 1 }
        it { expect(planting.photos.first).to eq photo }
        # there's only one photo, so that's the default
        it { expect(planting.default_photo).to eq photo }
        it { expect(planting.crop.default_photo).to eq photo }

        describe 'with a second older photo' do
          # Add an old photo
          before { planting.photos << old_photo }
          it { expect(planting.default_photo).to eq photo }
          it { expect(planting.crop.default_photo).to eq photo }

          describe 'and someone likes the old photo' do
            before { FactoryBot.create :like, likeable: old_photo }
            it { expect(planting.default_photo).to eq old_photo }
            it { expect(planting.crop.default_photo).to eq old_photo }
          end
        end
      end

      it 'to a harvest' do
        harvest.photos << photo
        expect(harvest.photos.size).to eq 1
        expect(harvest.photos.first).to eq photo
      end

      it 'to a seed' do
        seed.photos << photo
        expect(seed.photos.size).to eq 1
        expect(seed.photos.first).to eq photo
      end

      it 'to a garden' do
        garden.photos << photo
        expect(garden.photos.size).to eq 1
        expect(garden.photos.first).to eq photo
      end

      it 'to a post' do
        post.photos << photo
        expect(post.photos.size).to eq 1
        expect(post.photos.first).to eq photo
      end
    end

    context "removing photos" do
      it 'from a planting' do
        planting.photos << photo
        photo.destroy
        expect(planting.photos.size).to eq 0
      end

      it 'from a harvest' do
        harvest.photos << photo
        photo.destroy
        expect(harvest.photos.size).to eq 0
      end

      it 'from a garden' do
        garden.photos << photo
        photo.destroy
        expect(garden.photos.size).to eq 0
      end

      it "automatically if unused" do
        photo.destroy_if_unused
        expect(-> { photo.reload }).to raise_error ActiveRecord::RecordNotFound
      end

      it 'they are used by plantings but not harvests' do
        harvest.photos << photo
        planting.photos << photo
        harvest.destroy # photo is now used by harvest but not planting
        photo.destroy_if_unused
        expect(-> { photo.reload }).not_to raise_error
      end

      it 'they are used by harvests but not plantings' do
        harvest.photos << photo
        planting.photos << photo
        planting.destroy # photo is now used by harvest but not planting
        photo.destroy_if_unused
        expect(-> { photo.reload }).not_to raise_error
      end

      it 'they are used by gardens but not plantings' do
        garden.photos << photo
        planting.photos << photo
        planting.destroy # photo is now used by garden but not planting
        photo.destroy_if_unused
        expect(-> { photo.reload }).not_to raise_error
      end

      it 'they are no longer used by anything' do
        planting.photos << photo
        harvest.photos << photo
        garden.photos << photo
        expect(photo.plantings.size).to eq 1
        expect(photo.harvests.size).to eq 1
        expect(photo.gardens.size).to eq 1

        planting.destroy # photo is still used by harvest and garden
        photo.reload

        expect(photo.plantings.size).to eq 0
        expect(photo.harvests.size).to eq 1

        harvest.destroy
        garden.destroy # photo is now no longer used by anything
        photo.reload

        expect(photo.plantings.size).to eq 0
        expect(photo.harvests.size).to eq 0
        expect(photo.gardens.size).to eq 0
        photo.destroy_if_unused
        expect(-> { photo.reload }).to raise_error ActiveRecord::RecordNotFound
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
      photo = Photo.new(owner_id: 1)
      photo.should.respond_to? :flickr_metadata
    end
  end

  it 'excludes deleted members' do
    expect(Photo.joins(:owner).all).to include(photo)
    member.destroy
    expect(Photo.joins(:owner).all).not_to include(photo)
  end

  describe 'scopes' do
    let(:harvest_crop) { FactoryBot.create :crop }
    let!(:harvest)       { FactoryBot.create :harvest, owner: member, crop: harvest_crop }
    let!(:harvest_photo) { FactoryBot.create :photo, owner: member                       }

    let(:planting_crop) { FactoryBot.create :crop }
    let!(:planting)       { FactoryBot.create :planting, owner: member, crop: planting_crop }
    let!(:planting_photo) { FactoryBot.create :photo, owner: member                         }

    let(:seed_crop) { FactoryBot.create :crop }
    let!(:seed)       { FactoryBot.create :seed, owner: member, crop: seed_crop }
    let!(:seed_photo) { FactoryBot.create :photo, owner: member                 }

    before do
      harvest.photos << harvest_photo
      planting.photos << planting_photo
      seed.photos << seed_photo
    end

    it { expect(Photo.by_model(Harvest)).to eq([harvest_photo]) }
    it { expect(Photo.by_model(Planting)).to eq([planting_photo]) }
    it { expect(Photo.by_model(Seed)).to eq([seed_photo]) }

    it { expect(Photo.by_crop(harvest_crop)).to eq([harvest_photo]) }
    it { expect(Photo.by_crop(planting_crop)).to eq([planting_photo]) }
    it { expect(Photo.by_crop(seed_crop)).to eq([seed_photo]) }
  end
end
