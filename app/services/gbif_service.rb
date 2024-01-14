# frozen_string_literal: true

class GbifService
  def initialize
    @cropbot = Member.find_by(login_name: 'cropbot')
    @species = Gbif::Species
  end

  def suggest(term)
    # Query the GBIF name autocomplete and discover the scientific name.
    # [
    #   {
    #   "key": 2932942,
    #   "nameKey": 1970347,
    #   "kingdom": "Plantae",
    #   "phylum": "Tracheophyta",
    #   "order": "Solanales",
    #   "family": "Solanaceae",
    #   "genus": "Capsicum",
    #   "species": "Capsicum chinense",
    #   "kingdomKey": 6,
    #   "phylumKey": 7707728,
    #   "classKey": 220,
    #   "orderKey": 1176,
    #   "familyKey": 7717,
    #   "genusKey": 2932937,
    #   "speciesKey": 2932942,
    #   "parent": "Capsicum",
    #   "parentKey": 2932937,
    #   "nubKey": 2932942,
    #   "scientificName": "Capsicum chinense Jacq.",
    #   "canonicalName": "Capsicum chinense",
    #   "rank": "SPECIES",
    #   "status": "ACCEPTED",
    #   "synonym": false,
    #   "higherClassificationMap": {
    #   "6": "Plantae",
    #   "220": "Magnoliopsida",
    #   "1176": "Solanales",
    #   "7717": "Solanaceae",
    #   "2932937": "Capsicum",
    #   "7707728": "Tracheophyta"
    #   },
    #   "class": "Magnoliopsida"
    #   },
    #   {
    #   "key": 12079498,
    #   "nameKey": 81778754,
    #   "kingdom": "Plantae",
    #   "phylum": "Tracheophyta",
    #   "order": "Solanales",
    #   "family": "Solanaceae",
    #   "genus": "Capsicum",
    #   "species": "Capsicum chinense",
    #   "kingdomKey": 6,
    #   "phylumKey": 7707728,
    #   "classKey": 220,
    #   "orderKey": 1176,
    #   "familyKey": 7717,
    #   "genusKey": 2932937,
    #   "speciesKey": 2932942,
    #   "parent": "Capsicum",
    #   "parentKey": 2932937,
    #   "nubKey": 12079498,
    #   "scientificName": "Capsicum annuum var. chinense (Jacq.) Alef.",
    #   "canonicalName": "Capsicum annuum chinense",
    #   "rank": "VARIETY",
    #   "status": "SYNONYM",
    #   "synonym": true,
    #   "higherClassificationMap": {
    #   "6": "Plantae",
    #   "220": "Magnoliopsida",
    #   "1176": "Solanales",
    #   "7717": "Solanaceae",
    #   "2932937": "Capsicum",
    #   "2932942": "Capsicum chinense",
    #   "7707728": "Tracheophyta"
    #   },
    #   "class": "Magnoliopsida"
    #   }
    #   ]

    @species.name_suggest(q: term)
  end

  def import!
    Crop.order(updated_at: :desc).each do |crop|
      Rails.logger.debug { "#{crop.id}, #{crop.name}" }
      update_crop(crop) if crop.valid?
    end
  end

  def update_crop(crop)
    return unless crop.scientific_names.any?

    # Attempt to resolve the scientific names via /species/match.
    gbif_usage_key = crop.scientific_names.detect { |sn| sn.gbif_key.present? }
    unless gbif_usage_key
      crops.scientific_names.each do |sn|
        @species.name_backbone(q: sn.name, higherTaxonKey: 6, nameType: 'SCIENTIFIC')
        next unless result["confidence"] > 95 && result["matchType"] == "EXACT"

        sn.gbif_key = result["usageKey"]
        sn.gbif_rank = result["rank"]
        sn.gbif_status = result["status"]
        sn.save!
      end

      gbif_usage_key = crop.scientific_names.detect { |sn| sn.gbif_key.present? }
    end

    # No match? Fall back to common names
    unless gbif_usage_key
      query_results = @species.name_lookup(crop.name, higherTaxonKey: 6)

      # We only want one result, otherwise it needs human.
      return unless query_results.length == 1

      gbif_usage_key = query_results["results"].first["usageKey"]
    end

    gbif_record = fetch(gbif_usage_key)
    if gbif_record.present? && gbif_record.is_a?(String)
      Rails.logger.info(gbif_record)
    elsif gbif_record.present? && gbif_record.fetch('data', false)
      #   crop.update! openfarm_data: gbif_record.fetch('data', false)
      #   save_companions(crop, gbif_record)
      save_photos(crop, gbif_usage_key)
    else
      Rails.logger.debug "\tcrop not found on GBIF"
      #   crop.update!(openfarm_data: false)
    end
  end

  def save_photos(crop, key)
    #  https://api.gbif.org/v1/occurrence/search?taxon_key=3084850

    occurrences = Gbif::Occurrences.search(key, mediatype: 'StillImage', limit: 3, hasCoordinate: true)
    pictures = []
    occurrences["results"].each do |result|
      media = result["media"]

      # Example: "https://inaturalist-open-data.s3.amazonaws.com/photos/250226497/original.jpg"
      url = media["identifier"]
      Digest::MD5.hexdigest(url)

      next unless url.start_with? 'http'
      next if Photo.find_by(source_id: result["key"], source: 'gbif')

      pictures << result
    end

    pictures.each do |_picture|
      photo = Photo.new(
        source_id:     result["key"],
        source:        'gbif',
        owner:         @cropbot,
        thumbnail_url: thumbnail,
        fullsize_url:  url,
        title:         'GBIF photo', # TODO: By creator, publisher?
        license_name:  media["license"],
        link_url:      media["references"]
      )
      if photo.valid?
        Photo.transaction do
          photo.save
          PhotoAssociation.find_or_create_by! photo:, photographable: crop
        end
        Rails.logger.debug { "\t saved photo #{photo.id} #{photo.source_id}" }
      else
        Rails.logger.warn "Photo not valid"
      end
    end
  end

  def fetch(key)
    Gbif::Request.new("species/#{key}", nil, nil, nil).perform
  end
end
