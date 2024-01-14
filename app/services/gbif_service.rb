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
    Crop.all.order(updated_at: :desc).each do |crop|
      Rails.logger.debug { "#{crop.id}, #{crop.name}" }
      update_crop(crop) if crop.valid?
    end
  end

  def update_crop(crop)
    return unless crop.scientific_names.any?

    # Attempt to resolve the scientific names via /species/match.
    gbif_usage_key = crop.scientific_names.detect {|sn| sn.gbif_key.present? }
    unless gbif_usage_key
       crops.scientific_names.each do |sn|
          results = @species.name_backbone(q: sn.name, higherTaxonKey: 6, nameType: 'SCIENTIFIC')
          next unless result["confidence"] > 95 && result["matchType"] == "EXACT"

          sn.gbif_key = result["usageKey"]
          sn.gbif_rank = result["rank"]
          sn.gbif_status = result["status"]
          sn.save!
       end

       gbif_usage_key = crop.scientific_names.detect {|sn| sn.gbif_key.present? }
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
    #   save_photos(crop)
    else
      Rails.logger.debug "\tcrop not found on GBIF"
    #   crop.update!(openfarm_data: false)
    end
  end

  def save_photos(crop)
    pictures = fetch_pictures(crop.name)
    pictures.each do |picture|
      data = picture.fetch('attributes')
      Rails.logger.debug(data)
      next unless data.fetch('image_url').start_with? 'http'
      next if Photo.find_by(source_id: picture.fetch('id'), source: 'openfarm')

      photo = Photo.new(
        source_id:     picture.fetch('id'),
        source:        'openfarm',
        owner:         @cropbot,
        thumbnail_url: data.fetch('thumbnail_url'),
        fullsize_url:  data.fetch('image_url'),
        title:         'Open Farm photo',
        license_name:  'No rights reserved',
        link_url:      "https://openfarm.cc/en/crops/#{name_to_slug(crop.name)}"
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


  def fetch_pictures(name)
    body = conn.get("crops/#{name_to_slug(name)}/pictures.json").body
    body.fetch('data', false)
  rescue StandardError
    Rails.logger.debug "Error fetching photos"
    Rails.logger.debug []
  end

end
