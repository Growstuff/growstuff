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
      puts "Processing crop: #{crop.name}"
      wikidata_id = nil

      # Try to find Wikidata ID from the scientific_names table first
      if (sci_name_with_id = crop.scientific_names.find { |sn| sn.wikidata_id.present? })
        wikidata_id = sci_name_with_id.wikidata_id
        puts "  Found Wikidata ID in scientific_names table: #{wikidata_id}"
      # If not found, try the existing en_wikipedia_url method
      elsif crop.en_wikipedia_url.present?
        begin
          title = crop.en_wikipedia_url.split('/').last
          puts "  Searching for Wikidata ID using Wikipedia URL: #{crop.en_wikipedia_url}"

          # Get Wikidata ID from Wikipedia API
          wiki_uri = URI("https://en.wikipedia.org/w/api.php?action=query&prop=pageprops&titles=#{title}&format=json")
          wiki_response = Net::HTTP.get(wiki_uri)
          wiki_data = JSON.parse(wiki_response)
          pages = wiki_data['query']['pages']
          page_id = pages.keys.first

          if page_id != "-1" && pages[page_id]['pageprops'] && pages[page_id]['pageprops']['wikibase_item']
            wikidata_id = pages[page_id]['pageprops']['wikibase_item']
            puts "    Found Wikidata ID via Wikipedia URL: #{wikidata_id}"
          end
        rescue StandardError => e
          puts "    Error querying Wikipedia for URL #{crop.en_wikipedia_url}: #{e.message}"
        end
      end

      if wikidata_id
        begin
          # Get aliases from Wikidata API
          wikidata_uri = URI("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=#{wikidata_id}&props=aliases&format=json")
          wikidata_response = Net::HTTP.get(wikidata_uri)
          wikidata_data = JSON.parse(wikidata_response)

          aliases = wikidata_data.dig('entities', wikidata_id, 'aliases')
          if aliases
            aliases.each do |lang, values|
              values.each do |value|
                next if AlternateName.exists?(name: value['value'], language: lang, crop: crop)

                AlternateName.create!(
                  name:     value['value'],
                  language: lang,
                  crop:     crop,
                  creator:  creator
                )
                puts "      Added alternate name: #{value['value']} (#{lang})"
              end
            end
          else
            puts "    No aliases found for Wikidata ID: #{wikidata_id}"
          end
        rescue StandardError => e
          puts "    Error processing Wikidata aliases for #{crop.name}: #{e.message}"
        end
      else
        puts "  Could not find Wikidata ID for #{crop.name}"
      end
    end
  end
end
