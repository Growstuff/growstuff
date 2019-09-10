# frozen_string_literal: true

BASE = 'https://openfarm.cc/api/v1/'
# BASE = 'http://127.0.0.1:3000/api/v1/'

class OpenfarmService
  def initialize
    @cropbot = Member.find_by(login_name: 'cropbot')
  end

  def import!
    Crop.all.order(updated_at: :desc).each do |crop|
      puts crop.name
      update_crop(crop)
    end
  end

  def update_crop(crop)
    openfarm_record = fetch(crop.name)
    if openfarm_record.present?
      crop.update! openfarm_data: openfarm_record
      save_photos(crop)
    else
      puts "\tcrop not found on Open Farm"
      crop.touch :updated_at
    end
  end

  def save_photos(crop)
    pictures = fetch_pictures(crop.name)
    pictures.each do |p|
      data = p.fetch('attributes')
      photo = Photo.find_or_initialize_by(source_id: p.fetch('id'), source: 'openfarm')
      photo.owner = @cropbot
      photo.thumbnail_url = data.fetch('thumbnail_url')
      photo.fullsize_url = data.fetch('image_url')
      photo.title = 'Open Farm photo'
      photo.license_name = 'No rights reserved'
      photo.link_url = "https://openfarm.cc/en/crops/#{CGI.escape crop.name.downcase}"
      photo.save!

      PhotoAssociation.find_or_create_by! photo: photo, photographable: crop
      puts "\t created photo #{photo.id}"
    end
  end

  def fetch(name)
    body = conn.get("crops/#{name_to_slug(name)}.json").body
    puts body[0..100]
    body.fetch('data', {})
  rescue StandardError
    puts "error fetching crop"
    puts body
  end

  def name_to_slug(name)
    CGI.escape(name.sub(' ', '-').downcase)
  end

  def fetch_all(page)
    conn.get("crops.json?page=#{page}").body.fetch('data', {})
  end

  def fetch_pictures(name)
    body = conn.get("crops/#{name_to_slug(name)}/pictures.json").body
    body.fetch('data', false)
  rescue StandardError
    puts "Error fetching photos"
    puts body
  end

  private

  def conn
    Faraday.new BASE do |conn|
      conn.response :json, content_type: /\bjson$/
      conn.adapter Faraday.default_adapter
    end
  end
end
