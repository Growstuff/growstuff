# frozen_string_literal: true

require 'net/http'
require 'json'

namespace :wikidata do
  desc "Imports alternate names from Wikidata"
  task import_alternate_names: :environment do
    creator = Member.find_by(admin: true)
    unless creator
      puts "Could not find an admin member to assign as creator."
      return
    end

    Crop.all.each do |crop|
      next unless crop.en_wikipedia_url.present?

      begin
        title = crop.en_wikipedia_url.split('/').last
        puts "Processing crop: #{crop.name} (Wikipedia title: #{title})"

        # Get Wikidata ID from Wikipedia API
        wiki_uri = URI("https://en.wikipedia.org/w/api.php?action=query&prop=pageprops&titles=#{title}&format=json")
        wiki_response = Net::HTTP.get(wiki_uri)
        wiki_data = JSON.parse(wiki_response)
        page_id = wiki_data['query']['pages'].keys.first
        wikidata_id = wiki_data['query']['pages'][page_id]['pageprops']['wikibase_item']

        if wikidata_id
          puts "  Found Wikidata ID: #{wikidata_id}"
          # Get aliases from Wikidata API
          wikidata_uri = URI("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{wikidata_id}&props=aliases&format=json")
          wikidata_response = Net::HTTP.get(wikidata_uri)
          wikidata_data = JSON.parse(wikidata_response)

          aliases = wikidata_data['entities'][wikidata_id]['aliases']
          aliases.each do |lang, values|
            values.each do |value|
              next if AlternateName.exists?(name: value['value'], language: lang, crop: crop)

              AlternateName.create!(
                name:     value['value'],
                language: lang,
                crop:     crop,
                creator:  creator
              )
              puts "    Added alternate name: #{value['value']} (#{lang})"
            end
          end
        else
          puts "  Could not find Wikidata ID for #{crop.name}"
        end
      rescue StandardError => e
        puts "  Error processing crop #{crop.name}: #{e.message}"
      end
    end
  end
end
