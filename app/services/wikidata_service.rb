# frozen_string_literal: true

require 'net/http'
require 'json'

class WikidataService
  CELSIUS_UNIT_ID = 'http://www.wikidata.org/entity/Q25267'
  FAHRENHEIT_UNIT_ID = 'http://www.wikidata.org/entity/Q42289'

  def self.find_wikidata_id(location_name)
    return nil if location_name.blank?

    uri = URI("https://www.wikidata.org/w/api.php?action=wbsearchentities&search=#{URI.encode_www_form_component(location_name)}&language=en&format=json")
    req = Net::HTTP::Get.new(uri)
    req['User-Agent'] = "Growstuff (https://www.growstuff.org; admin@growstuff.org)"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    data = JSON.parse(response.body)
    data.dig('search', 0, 'id')
  rescue StandardError => e
    Rails.logger.error "WikidataService.find_wikidata_id error: #{e.message}"
    nil
  end

  def self.fetch_temps(wikidata_id)
    return {} if wikidata_id.blank?

    uri = URI("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{wikidata_id}&props=claims&format=json")
    req = Net::HTTP::Get.new(uri)
    req['User-Agent'] = "Growstuff (https://www.growstuff.org; admin@growstuff.org)"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    data = JSON.parse(response.body)
    claims = data.dig('entities', wikidata_id, 'claims') || {}

    highest_temp = extract_temp(claims['P6591'])
    lowest_temp = extract_temp(claims['P7422'])

    {
      highest_temp_c: highest_temp,
      lowest_temp_c: lowest_temp
    }
  rescue StandardError => e
    Rails.logger.error "WikidataService.fetch_temps error: #{e.message}"
    {}
  end

  def self.extract_temp(claim_data)
    return nil if claim_data.blank?

    # We take the first value
    main_snak = claim_data.first&.dig('mainsnak')
    return nil unless main_snak&.dig('datavalue', 'type') == 'quantity'

    quantity_data = main_snak.dig('datavalue', 'value')
    amount = quantity_data['amount'].to_f
    unit = quantity_data['unit']

    case unit
    when CELSIUS_UNIT_ID
      amount
    when FAHRENHEIT_UNIT_ID
      (amount - 32) * 5.0 / 9.0
    else
      nil
    end
  end
end
