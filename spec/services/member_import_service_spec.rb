# frozen_string_literal: true

require 'rails_helper'

describe MemberImportService, type: :service do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:connection) { Faraday.new { |f| f.adapter :test, stubs } }
  let(:out) { StringIO.new }
  let(:options) do
    { login_name: 'Shiny', connection: connection, delay: 0, backoff: 0, out: out, sleeper: ->(_seconds) {} }
  end

  # One stub serves everything from `responses`, so examples can override any path.
  # Site JSON lists are paged with ?page=N: page 1 gets the rows, later pages are empty.
  let(:responses) { {} }
  let(:requested_paths) { [] }
  let(:requested_queries) { {} }

  def serve_json_api(path, data)
    responses[path] = [200, { data: data }.to_json]
  end

  def serve_rows(path, rows)
    responses[path] = [200, rows.to_json]
  end

  def fail_with(path, status)
    responses[path] = [status, '']
  end

  def garden_row(id, name: 'Back garden', slug: 'shiny-back-garden', owner_id: 15, **extra)
    { id: id, name: name, slug: slug, owner_id: owner_id, description: 'very shade', active: true,
      location: 'Wellington, New Zealand', latitude: -41.28, longitude: 174.77, area: nil, area_unit: nil,
      location_wikidata_id: 'Q23661', lowest_temp_c: nil, highest_temp_c: nil,
      created_at: '2016-09-04T03:00:19.377Z', updated_at: '2016-09-04T03:00:19.377Z' }.merge(extra)
  end

  def planting_row(id, slug: 'shiny-back-garden-tomato', garden_id: 70, crop_id: 216, **extra)
    { id: id, slug: slug, garden_id: garden_id, crop_id: crop_id, owner_id: 15, planted_at: '2013-02-27',
      quantity: 3, description: 'Went well', sunniness: 'sun', planted_from: 'seed', failed: false,
      finished: true, finished_at: '2013-09-01', overall_rating: 4, created_at: '2013-02-27T01:00:00.000Z' }.merge(extra)
  end

  def crop_resource(id, name)
    { id: id.to_s, type: 'crops',
      attributes: { name: name, 'en-wikipedia-url': "https://en.wikipedia.org/wiki/#{name}", perennial: false } }
  end

  def photo_row(id, flickr_id: '8976339714', owner_id: 15, **extra)
    { id: id, owner_id: owner_id, title: "photo #{id}", license_name: 'Attribution License',
      license_url: 'https://creativecommons.org/licenses/by/2.0/', source: 'flickr', source_id: flickr_id,
      thumbnail_url: "https://farm8.staticflickr.com/7368/#{flickr_id}_abc_q.jpg",
      fullsize_url: "https://farm8.staticflickr.com/7368/#{flickr_id}_abc_z.jpg",
      link_url: "https://www.flickr.com/photos/97098138@N08/#{flickr_id}",
      date_taken: '2013-06-07T08:43:50.000Z' }.merge(extra)
  end

  before do
    stubs.get(%r{\A/(api/v1/crops|members/shiny|plantings)/?}) do |env|
      requested_paths << env.url.path
      requested_queries[env.url.path] = env.params.dup
      status, body = responses.fetch(env.url.path, [404, ''])
      # Only the first page of a site JSON list has anything on it.
      body = '[]' if env.params['page'].to_i > 1
      [status, {}, body]
    end
    serve_json_api('/api/v1/members', [{ id: '15', attributes: { 'login-name': 'shiny', slug: 'shiny' } }])
    stubs.get('/api/v1/members') { [200, {}, responses['/api/v1/members'][1]] }

    serve_rows('/members/shiny/gardens.json', [garden_row(70)])
    serve_rows('/members/shiny/plantings.json', [planting_row(700)])
    serve_json_api('/api/v1/crops/216', crop_resource(216, 'tomato'))
    serve_rows('/plantings/shiny-back-garden-tomato/photos.json', [])
  end

  around { |example| VCR.turned_off(&example) }

  describe '#call' do
    it 'creates the local member when missing' do
      stats = described_class.new(**options).call

      expect(Member.find_by(login_name: 'Shiny')).to be_confirmed
      expect(stats[:members_created]).to eq 1
      expect(out.string).to include('password')
    end

    it 'uses an existing local member' do
      member = create(:member, login_name: 'Shiny')

      stats = described_class.new(**options).call

      expect(stats[:members_created]).to eq 0
      expect(member.gardens.pluck(:name)).to include('Back garden')
    end

    it 'imports gardens with their location and details, without geocoding' do
      expect(WikidataService).not_to receive(:find_wikidata_id)

      stats = described_class.new(**options).call

      garden = Garden.find_by!(slug: 'shiny-back-garden')
      expect(garden).to have_attributes(name: 'Back garden', description: 'very shade', active: true,
                                        location: 'Wellington, New Zealand', latitude: -41.28,
                                        location_wikidata_id: 'Q23661')
      expect(garden.created_at.year).to eq 2016
      expect(stats[:gardens_created]).to eq 1
    end

    it 'only imports gardens the member owns, not ones they merely collaborate on' do
      serve_rows('/members/shiny/gardens.json',
                 [garden_row(70), garden_row(71, name: 'Theirs', slug: 'other-theirs', owner_id: 99)])

      described_class.new(**options).call

      expect(Garden.find_by(slug: 'other-theirs')).to be_nil
    end

    it 'imports plantings, fetching just the crop they use' do
      stats = described_class.new(**options).call

      planting = Planting.find_by!(slug: 'shiny-back-garden-tomato')
      expect(planting.garden.slug).to eq 'shiny-back-garden'
      expect(planting.crop.name).to eq 'tomato'
      expect(planting).to have_attributes(quantity: 3, finished: true, finished_at: Date.new(2013, 9, 1),
                                          overall_rating: 4)
      expect(requested_paths.count('/api/v1/crops/216')).to eq 1
      expect(stats).to include(gardens_created: 1, plantings_created: 1)
    end

    it 'fetches each crop only once' do
      serve_rows('/members/shiny/plantings.json',
                 [planting_row(700), planting_row(701, slug: 'shiny-back-garden-tomato-2')])
      serve_rows('/plantings/shiny-back-garden-tomato-2/photos.json', [])

      described_class.new(**options).call

      expect(requested_paths.count('/api/v1/crops/216')).to eq 1
      expect(Planting.count).to eq 2
    end

    it 'is safe to run twice' do
      described_class.new(**options).call
      stats = described_class.new(**options).call

      expect(Garden.where(slug: 'shiny-back-garden').count).to eq 1
      expect(Planting.count).to eq 1
      expect(stats[:plantings_updated]).to eq 1
      expect(stats[:members_created]).to eq 0
    end

    it 'skips plantings whose crop no longer exists on the source site' do
      responses['/api/v1/crops/216'] = [404, '']

      stats = described_class.new(**options).call

      expect(Planting.count).to eq 0
      expect(stats[:plantings_skipped_crop_missing]).to eq 1
    end

    it 'skips plantings in gardens that were not imported' do
      serve_rows('/members/shiny/plantings.json', [planting_row(700, garden_id: 999)])

      stats = described_class.new(**options).call

      expect(Planting.count).to eq 0
      expect(stats[:plantings_skipped_garden_not_imported]).to eq 1
    end

    it 'refuses to take over a planting that belongs to another member' do
      create(:planting, slug: 'shiny-back-garden-tomato')

      stats = described_class.new(**options).call

      expect(stats[:failed]).to eq 1
      expect(Planting.count).to eq 1
    end

    it 'stops when the member does not exist on the source site' do
      responses['/api/v1/members'] = [200, { data: [] }.to_json]

      expect { described_class.new(**options).call }
        .to raise_error(described_class::Aborted, /No member called "Shiny"/)
      expect(Member.find_by(login_name: 'Shiny')).to be_nil
    end
  end

  describe 'active_only' do
    it 'asks for everything by default' do
      described_class.new(**options).call

      expect(requested_queries['/members/shiny/gardens.json']).to include('all' => '1')
      expect(requested_queries['/members/shiny/plantings.json']).to include('all' => '1')
    end

    it 'leaves out the all flag so the site lists only active gardens and current plantings' do
      described_class.new(**options, active_only: true).call

      expect(requested_queries['/members/shiny/gardens.json']).not_to have_key('all')
      expect(requested_queries['/members/shiny/plantings.json']).not_to have_key('all')
    end
  end

  describe 'photos' do
    it 'imports planting photos as Flickr records pointing at Flickr URLs' do
      serve_rows('/plantings/shiny-back-garden-tomato/photos.json', [photo_row(1)])

      stats = described_class.new(**options).call

      photo = Photo.find_by!(title: 'photo 1')
      expect(photo).to have_attributes(fullsize_url: 'https://farm8.staticflickr.com/7368/8976339714_abc_z.jpg',
                                       source: 'flickr', source_id: '8976339714',
                                       license_url: 'https://creativecommons.org/licenses/by/2.0/')
      expect(photo.plantings.pluck(:slug)).to eq ['shiny-back-garden-tomato']
      expect(photo.owner.login_name).to eq 'Shiny'
      expect(stats).to include(photos_created: 1, photos_linked: 1)
    end

    it 'does not duplicate photos or links on a second run' do
      serve_rows('/plantings/shiny-back-garden-tomato/photos.json', [photo_row(1)])

      described_class.new(**options).call
      stats = described_class.new(**options).call

      expect(Photo.count).to eq 1
      expect(PhotoAssociation.where(photographable_type: 'Planting').count).to eq 1
      expect(stats[:photos_unchanged]).to eq 1
    end

    it 'ignores photos that belong to someone else' do
      serve_rows('/plantings/shiny-back-garden-tomato/photos.json', [photo_row(1, owner_id: 99)])

      described_class.new(**options).call

      expect(Photo.count).to eq 0
    end

    it 'skips photo requests entirely when photos: false' do
      described_class.new(**options, photos: false).call

      expect(requested_paths).not_to include('/plantings/shiny-back-garden-tomato/photos.json')
    end
  end

  describe 'when the server struggles' do
    it 'stops with a helpful message' do
      fail_with('/members/shiny/plantings.json', 503)

      expect { described_class.new(**options, max_retries: 1).call }
        .to raise_error(described_class::Aborted, /still failing.*re-running picks up/m)
    end
  end
end
