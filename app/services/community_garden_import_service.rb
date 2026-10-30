# frozen_string_literal: true

require 'net/http'
require 'json'

# Queries Overpass Turbo for community gardens and imports/updates CommunityGarden records.
class CommunityGardenImportService
  OVERPASS_URL = 'https://overpass-api.de/api/interpreter'
  OVERPASS_QUERY = <<~QUERY
    [out:json][timeout:25];
    // gather results
    nwr["leisure"="garden"]["garden:type"="community"]({{bbox}});
    // print results
    out geom;
  QUERY

  def initialize(bbox: nil, out: $stdout)
    @bbox = bbox
    @out = out
  end

  def call
    query = build_query
    response_body = fetch_overpass_data(query)
    return unless response_body

    data = JSON.parse(response_body)
    elements = data['elements'] || []

    imported_count = 0
    elements.each do |element|
      garden = process_element(element)
      imported_count += 1 if garden
    end

    @out.puts "Imported #{imported_count} community gardens."
    imported_count
  end

  def build_query
    if @bbox.present?
      formatted_bbox = @bbox.to_s.strip
      if formatted_bbox.start_with?('(') && formatted_bbox.end_with?(')')
        OVERPASS_QUERY.gsub('({{bbox}})', formatted_bbox)
      else
        OVERPASS_QUERY.gsub('{{bbox}}', formatted_bbox)
      end
    else
      OVERPASS_QUERY.gsub('({{bbox}})', '')
    end
  end

  private

  def fetch_overpass_data(query)
    uri = URI(OVERPASS_URL)
    response = Net::HTTP.post_form(uri, { 'data' => query })
    unless response.is_a?(Net::HTTPSuccess)
      @out.puts "Overpass API error: #{response.code} #{response.message}"
      return nil
    end
    response.body
  rescue StandardError => e
    @out.puts "HTTP request failed: #{e.message}"
    nil
  end

  def process_element(element)
    tags = element['tags'] || {}
    osm_id = "#{element['type']}/#{element['id']}"

    title = tags['name'].presence || tags['official_name'].presence || tags['alt_name'].presence ||
            tags['description'].presence || "Community Garden #{element['id']}"
    website = tags['website'].presence || tags['contact:website'].presence || tags['url'].presence
    email = tags['email'].presence || tags['contact:email'].presence
    wikidata_id = tags['wikidata'].presence || tags['brand:wikidata'].presence
    description = tags['description'].presence || tags['note'].presence || tags['comment'].presence
    coordinates = extract_coordinates(element)

    garden = CommunityGarden.find_by(osm_id: osm_id) ||
             CommunityGarden.find_by(osm_id: element['id'].to_s) ||
             CommunityGarden.new(osm_id: osm_id)

    garden.assign_attributes(
      title: title,
      website: website,
      email: email,
      wikidata_id: wikidata_id,
      description: description,
      coordinates: coordinates
    )

    garden.save!
    garden
  rescue StandardError => e
    @out.puts "Failed to import garden #{element['id']}: #{e.message}"
    nil
  end

  def extract_coordinates(element)
    lat = nil
    lon = nil

    if element['lat'].present? && element['lon'].present?
      lat = element['lat'].to_f
      lon = element['lon'].to_f
    elsif element['center'].is_a?(Hash)
      lat = element['center']['lat']&.to_f
      lon = element['center']['lon']&.to_f
    elsif element['geometry'].is_a?(Array) && element['geometry'].present?
      valid_geoms = element['geometry'].select { |g| g['lat'].present? && g['lon'].present? }
      if valid_geoms.present?
        lat = valid_geoms.sum { |g| g['lat'].to_f } / valid_geoms.size.to_f
        lon = valid_geoms.sum { |g| g['lon'].to_f } / valid_geoms.size.to_f
      end
    elsif element['bounds'].is_a?(Hash)
      bounds = element['bounds']
      if bounds['minlat'].present? && bounds['maxlat'].present? && bounds['minlon'].present? && bounds['maxlon'].present?
        lat = (bounds['minlat'].to_f + bounds['maxlat'].to_f) / 2.0
        lon = (bounds['minlon'].to_f + bounds['maxlon'].to_f) / 2.0
      end
    end

    return nil unless lat && lon

    "#{lat}, #{lon}"
  end
end
