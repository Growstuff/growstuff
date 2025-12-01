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

      # Try to find Wikidata ID using scientific names first
      crop.scientific_names.each do |sci_name|
        begin
          puts "  Searching for Wikidata ID using scientific name: #{sci_name.name}"
          title = sci_name.name.tr(' ', '_') # Wikipedia titles use underscores
          wiki_uri = URI("https://en.wikipedia.org/w/api.php?action=query&prop=pageprops&titles=#{title}&format=json")
          wiki_response = Net::HTTP.get(wiki_uri)
          wiki_data = JSON.parse(wiki_response)

          # The response for a non-existent page has a key of "-1"
          pages = wiki_data['query']['pages']
          page_id = pages.keys.first

          if page_id != "-1" && pages[page_id]['pageprops'] && pages[page_id]['pageprops']['wikibase_item']
            wikidata_id = pages[page_id]['pageprops']['wikibase_item']
            puts "    Found Wikidata ID via scientific name: #{wikidata_id}"
            break # Found it, so we can stop looping through scientific names
          else
            puts "    No Wikidata ID found for scientific name: #{sci_name.name}"
          end
        rescue StandardError => e
          puts "    Error querying Wikipedia for scientific name #{sci_name.name}: #{e.message}"
        end
      end

      # If not found via scientific name, try the existing en_wikipedia_url method
      if !wikidata_id && crop.en_wikipedia_url.present?
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
