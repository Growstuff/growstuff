# frozen_string_literal: true

require 'rails_helper'

describe GbifService, :vcr, type: :service do
  let(:scientific_name_tomato) { create(:solanum_lycopersicum) }
  let(:tomato) { scientific_name_tomato.crop }

  let(:gbif_service) { described_class.new }

  # TODO: Find places where we should just use dependency injection to insert the cropbot user.
  before do
    # don't use 'let' for this -- we need to actually create it,
    # regardless of whether it's used.
    @cropbot = FactoryBot.create(:cropbot)
  end

  describe "#fetch" do
    it "fetches a given key" do
      result = gbif_service.fetch(2_930_137)
      expect(result["key"]).to eq 2_930_137
      expect(result["family"]).to eq "Solanaceae"
    end
  end

  describe "#suggest" do
    it "matches" do
      results = gbif_service.suggest(scientific_name_tomato.name)
      expect(results[0]["key"]).to eq 2_930_137
      expect(results[0]["family"]).to eq "Solanaceae"
    end
  end

  describe "#import!"
  describe "#update_crop" do
    it "resolves scientific names" do
      gbif_service.update_crop(tomato)

      scientific_name_tomato.reload
      expect(scientific_name_tomato.gbif_key).to eq 2_930_137
    end

    it "resolves common names" do
      crop = create(:crop, name: "Habanero")

      gbif_service.update_crop(crop)
      crop.reload

      expect(crop.scientific_names.first.name).to eq "Capsicum chinense"
    end

    it "gets photos" do
      scientific_name_tomato.update(gbif_key: "2930137")

      gbif_service.update_crop(tomato)

      tomato.reload
      expect(tomato.photos.count).to eq 3

      photo = tomato.photos.order(:id)[0]
      expect(photo.fullsize_url).to eq "https://inaturalist-open-data.s3.amazonaws.com/photos/343874350/original.jpeg"
      expect(photo.thumbnail_url).to eq "https://api.gbif.org/v1/image/cache/200x/occurrence/4507688130/media/7bc2c1b87c7110b785674bfc198d891c"
      expect(photo.title).to eq "Photo by Ingeborg van Leeuwen via iNaturalist (Copyright Ingeborg van Leeuwen)"
      expect(photo.license_name).to eq "CC BY-NC 4.0"
      expect(photo.license_url).to eq "http://creativecommons.org/licenses/by-nc/4.0/"
      expect(photo.link_url).to eq "https://www.inaturalist.org/photos/343874350"
      expect(photo.source_id).to eq("4507688130")
      expect(photo.source).to eq("gbif")
      expect(photo.date_taken).to eq("2024-01-01T11:07:00.000+00:00")
    end
  end
end
