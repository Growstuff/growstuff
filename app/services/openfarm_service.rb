# frozen_string_literal: true

BASE = 'https://openfarm.cc/api/v1/'
# BASE = 'http://127.0.0.1:3000/api/v1/'

class OpenfarmService
  def import!
    Crop.all.order(updated_at: :desc).each do |crop|
      puts crop.name
      update_crop(crop)
    rescue StandardError
      puts "ERROR"
    end
  end

  def update_crop(crop)
    openfarm_record = fetch_one(crop.name)
    crop.update! openfarm_data: openfarm_record if openfarm_record.fetch('attributes', false)
  end

  private

  def fetch_one(name)
    body = conn.get("crops/#{CGI.escape name.downcase}.json").body
    body.fetch('data', {})
  end

  def fetch_all(page)
    conn.get("crops.json?page=#{page}").body.fetch('data', {})
  end

  def conn
    Faraday.new BASE do |conn|
      conn.response :json, content_type: /\bjson$/
      conn.adapter Faraday.default_adapter
    end
  end
end
