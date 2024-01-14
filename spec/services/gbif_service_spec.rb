# frozen_string_literal: true

require 'rails_helper'

describe GbifService, :vcr, type: :service do
  let(:scientific_name_tomato) { create(:solanum_lycopersicum) }
  let(:tomato) { scientific_name_tomato.crop }

  let(:gbif_service) { GbifService.new }

  describe "#fetch" do
    it "fetches a given key" do
      result = gbif_service.fetch(2_930_137)
      expect(result["key"]).to eq "2930137"
      expect(result["family"]).to eq "Solanaceae"
    end
  end

  context "with a crop" do
    context "with a scientific name" do
      describe "#suggest" do
        it "matches" do
          results = gbif_service.suggest(scientific_name_tomato.name)
          expect(results[0]["key"]).to eq 2_930_137
          expect(results[0]["family"]).to eq "Solanaceae"
        end
      end

      describe "#fetch_photos" do
      end

      describe "#import!"
      describe "#update_crop" do
        #   def update_crop(crop)
        #     return unless crop.scientific_names.any?

        #     # Attempt to resolve the scientific names via /species/match.
        #     gbif_usage_key = crop.scientific_names.detect { |sn| sn.gbif_key.present? }
        #     unless gbif_usage_key
        #       crops.scientific_names.each do |sn|
        #         @species.name_backbone(q: sn.name, higherTaxonKey: 6, nameType: 'SCIENTIFIC')
        #         next unless result["confidence"] > 95 && result["matchType"] == "EXACT"

        #         sn.gbif_key = result["usageKey"]
        #         sn.gbif_rank = result["rank"]
        #         sn.gbif_status = result["status"]
        #         sn.save!
        #       end

        #       gbif_usage_key = crop.scientific_names.detect { |sn| sn.gbif_key.present? }
        #     end

        #     # No match? Fall back to common names
        #     unless gbif_usage_key
        #       query_results = @species.name_lookup(crop.name, higherTaxonKey: 6)

        #       # We only want one result, otherwise it needs human.
        #       return unless query_results.length == 1

        #       gbif_usage_key = query_results["results"].first["usageKey"]
        #     end

        #     gbif_record = fetch(gbif_usage_key)
        #     if gbif_record.present? && gbif_record.is_a?(String)
        #       Rails.logger.info(gbif_record)
        #     elsif gbif_record.present? && gbif_record.fetch('data', false)
        #       #   crop.update! openfarm_data: gbif_record.fetch('data', false)
        #       #   save_companions(crop, gbif_record)
        #       save_photos(crop, gbif_usage_key)
        #     else
        #       Rails.logger.debug "\tcrop not found on GBIF"
        #       #   crop.update!(openfarm_data: false)
        #     end
        #   end
      end

      describe "#save_photos(crop, key)" do
        #  https://api.gbif.org/v1/occurrence/search?taxon_key=3084850

        #     occurrences = Gbif::Occurrences.search(key, mediatype: 'StillImage', limit: 3, hasCoordinate: true)
        #     pictures = []
        #     occurrences["results"].each do |result|
        #       media = result["media"]

        #       # Example: "https://inaturalist-open-data.s3.amazonaws.com/photos/250226497/original.jpg"
        #       url = media["identifier"]
        #       Digest::MD5.hexdigest(url)

        #       next unless url.start_with? 'http'
        #       next if Photo.find_by(source_id: result["key"], source: 'gbif')

        #       pictures << result
        #     end

        #     pictures.each do |_picture|
        #       photo = Photo.new(
        #         source_id:     result["key"],
        #         source:        'gbif',
        #         owner:         @cropbot,
        #         thumbnail_url: thumbnail,
        #         fullsize_url:  url,
        #         title:         'GBIF photo', # TODO: By creator, publisher?
        #         license_name:  media["license"],
        #         link_url:      media["references"]
        #       )
        #       if photo.valid?
        #         Photo.transaction do
        #           photo.save
        #           PhotoAssociation.find_or_create_by! photo:, photographable: crop
        #         end
        #         Rails.logger.debug { "\t saved photo #{photo.id} #{photo.source_id}" }
        #       else
        #         Rails.logger.warn "Photo not valid"
        #       end
        #     end
        #   end
      end
    end
  end
end
