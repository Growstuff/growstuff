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
    # Attempt to resolve the scientific names via /species/match.
    gbif_usage_key = crop.scientific_names.detect { |sn| sn.gbif_key.present? }&.gbif_key
    unless gbif_usage_key
      crop.scientific_names.each do |sn|
        result = @species.name_backbone(name: sn.name) # , higherTaxonKey: 6, nameType: 'SCIENTIFIC')
        next unless result["confidence"] > 95 && result["matchType"] == "EXACT"

        sn.gbif_key = result["usageKey"]
        sn.gbif_rank = result["rank"]
        sn.gbif_status = result["status"]
        sn.save!
      end

      gbif_usage_key = crop.scientific_names.detect { |sn| sn.gbif_key.present? }&.gbif_key
    end

    # No match? Fall back to common names
    unless gbif_usage_key
      query_results = @species.name_lookup(q: crop.name, higherTaxonKey: 6)

      # We only want one result, otherwise it needs human.
      return unless query_results["results"].length == 1

      query_result = query_results["results"].first

      gbif_usage_key = query_result["key"]

      crop.scientific_names.create!(gbif_key: gbif_usage_key, name: query_result["canonicalName"], creator: @cropbot)
    end

    gbif_record = fetch(gbif_usage_key)
    if gbif_record.present?
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

    occurrences = Gbif::Occurrences.search(taxonKey: key, mediatype: 'StillImage', limit: 3, hasCoordinate: true)
    occurrences["results"].each do |result|
      next unless result["media"]

      media = result["media"].first

      # Example: "https://inaturalist-open-data.s3.amazonaws.com/photos/250226497/original.jpg"
      url = media["identifier"]
      md5 = Digest::MD5.hexdigest(url)
      width = 200
      thumbnail = "https://api.gbif.org/v1/image/cache/#{width}x/occurrence/#{result['key']}/media/#{md5}"

      next unless url.start_with? 'http'
      next if Photo.find_by(source_id: result["key"], source: 'gbif')

      photo = Photo.new(
        # This is for the overall observation which may technically have multiple media. However, we're only taking the first.
        source_id:     result["key"],
        source:        'gbif',
        owner:         @cropbot,
        thumbnail_url: thumbnail,
        fullsize_url:  url,
        title:         "Photo by #{media['creator']} via #{media['publisher']} (Copyright #{media['rightsHolder']})",
        license_name:  case media["license"]
                       when "http://creativecommons.org/licenses/by/4.0/"
                         "CC BY 4.0"
                       when "http://creativecommons.org/licenses/by-nc/4.0/"
                         "CC BY-NC 4.0"
                       else
                         media["license"]
                       end,
        license_url:   media["license"],
        link_url:      media["references"]
      )
      photo.date_taken = DateTime.parse(media["created"]) if media["created"]
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
