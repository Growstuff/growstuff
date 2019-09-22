# frozen_string_literal: true

BASE = 'https://openfarm.cc/api/v1/'
# BASE = 'http://127.0.0.1:3000/api/v1/'

class OpenfarmService
  def initialize
    @cropbot = Member.find_by(login_name: 'cropbot')
  end

  def import!
    Crop.all.order(updated_at: :desc).each do |crop|
      Rails.logger.debug("#{crop.id}, #{crop.name}")
      update_crop(crop) if crop.valid?
    end
  end

  def update_crop(crop)
    openfarm_record = fetch(crop.name)
    if openfarm_record.present? && openfarm_record.fetch('data', false)
      crop.update! openfarm_data: openfarm_record.fetch('data', false)
      save_companions(crop, openfarm_record)
      save_photos(crop)
    else
      Rails.logger.debug "\tcrop not found on Open Farm"
      crop.update!(openfarm_data: false)
    end
  end

  def save_companions(crop, openfarm_record)
    companions = openfarm_record.fetch('data').fetch('relationships').fetch('companions').fetch('data')
    crops = openfarm_record.fetch('included', []).select { |rec| rec["type"] == 'crops' }
    companions.each do |com|
      companion_crop_hash = crops.detect { |c| c.fetch('id') == com.fetch('id') }
      companion_crop_name = companion_crop_hash.fetch('attributes').fetch('name').downcase
      companion_crop = Crop.where('lower(name) = ?', companion_crop_name).first
      if companion_crop.nil?
        companion_crop = Crop.create!(name: companion_crop_name, requester: @cropbot, approval_status: "pending")
        # companion_crop.update_openfarm_data!
      end
      crop.companions << companion_crop unless crop.companions.where(id: companion_crop.id).any?
    end
  end

  def save_photos(crop)
    pictures = fetch_pictures(crop.name)
    pictures.each do |p|
      data = p.fetch('attributes')
      next unless data.fetch('image_url').start_with? 'http'

      photo = Photo.find_or_initialize_by(source_id: p.fetch('id'), source: 'openfarm')
      photo.owner = @cropbot
      photo.thumbnail_url = data.fetch('thumbnail_url')
      photo.fullsize_url = data.fetch('image_url')
      photo.title = 'Open Farm photo'
      photo.license_name = 'No rights reserved'
      photo.link_url = "https://openfarm.cc/en/crops/#{name_to_slug(crop.name)}"
      photo.save!

      PhotoAssociation.find_or_create_by! photo: photo, photographable: crop
      Rails.logger.debug "\t created photo #{photo.id}"
    end
  end

  def fetch(name)
    conn.get("crops/#{name_to_slug(name)}.json").body
  rescue NoMethodError
    Rails.logger.debug "error fetching crop"
    Rails.logger.debug "BODY: "
    Rails.logger.debug body
    Rails.logger.debug " =================== "
  end

  def name_to_slug(name)
    CGI.escape(name.gsub(' ', '-').downcase)
  end

  def fetch_all(page)
    conn.get("crops.json?page=#{page}").body.fetch('data', {})
  end

  def fetch_pictures(name)
    body = conn.get("crops/#{name_to_slug(name)}/pictures.json").body
    body.fetch('data', false)
  rescue StandardError
    Rails.logger.debug "Error fetching photos"
    Rails.logger.debug []
  end

  private

  def conn
    Faraday.new BASE do |conn|
      conn.response :json, content_type: /\bjson$/
      conn.adapter Faraday.default_adapter
    end
  end
end
