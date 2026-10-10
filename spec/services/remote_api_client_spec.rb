# frozen_string_literal: true

require 'rails_helper'

describe RemoteApiClient, type: :service do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:connection) { Faraday.new(url: 'https://source.test') { |f| f.adapter :test, stubs } }
  let(:sleeps) { [] }
  let(:client) do
    described_class.new(connection: connection, delay: 1, backoff: 5, out: StringIO.new,
                        sleeper: ->(seconds) { sleeps << seconds })
  end

  around { |example| VCR.turned_off(&example) }

  def json(body, status = 200)
    [status, {}, body.to_json]
  end

  describe '#each_page (JSON:API)' do
    it 'follows links.next verbatim, whatever paging scheme the server uses' do
      stubs.get('/things') do |env|
        offset = env.params.dig('page', 'offset').to_i
        next json(data: [{ id: '1' }], links: { next: 'https://source.test/things?page[offset]=1' }) if offset.zero?

        json(data: [{ id: '2' }], links: {})
      end

      pages = []
      client.each_page('/things') { |resources, _page| pages << resources.pluck('id') }

      expect(pages).to eq [['1'], ['2']]
      expect(sleeps).to eq [1]
    end

    it 'stops rather than loop when the server keeps sending the same next link' do
      stubs.get('/things') { json(data: [{ id: '1' }], links: { next: 'https://source.test/things?page[offset]=1' }) }

      expect { client.each_page('/things') { |_resources, _page| nil } }
        .to raise_error(described_class::Aborted, /same next page/)
    end

    it 'refuses to follow a next link to another host' do
      stubs.get('/things') { json(data: [{ id: '1' }], links: { next: 'https://elsewhere.test/things' }) }

      expect { client.each_page('/things') { |_resources, _page| nil } }
        .to raise_error(described_class::Aborted, /another host/)
    end

    it 'aborts on a response without data' do
      stubs.get('/things') { json(errors: [{ status: '500' }]) }

      expect { client.each_page('/things') { |_resources, _page| nil } }
        .to raise_error(described_class::Aborted, /unexpected response/)
    end
  end

  describe 'request headers' do
    it 'identifies itself and asks for JSON:API, which production insists on' do
      client = described_class.new(source_url: 'https://source.test', out: StringIO.new, sleeper: ->(_seconds) {})
      headers = client.send(:build_connection, 'https://source.test').headers

      expect(headers['Accept']).to eq 'application/vnd.api+json'
      expect(headers['User-Agent']).to include('Growstuff')
    end
  end

  describe '#get_resource' do
    it 'returns the resource' do
      stubs.get('/things/1') { json(data: { id: '1', type: 'things' }) }

      expect(client.get_resource('/things/1')).to include('id' => '1')
    end

    it 'returns nil for a missing resource instead of aborting' do
      stubs.get('/things/9') { [404, {}, ''] }

      expect(client.get_resource('/things/9')).to be_nil
    end
  end

  describe '#each_site_page (plain JSON)' do
    it 'pages with ?page=N until an empty page' do
      stubs.get('/things.json') do |env|
        rows = { '1' => [{ 'id' => 1 }, { 'id' => 2 }], '2' => [{ 'id' => 3 }] }
        json(rows.fetch(env.params['page'], []))
      end

      pages = []
      client.each_site_page('/things.json') { |rows, page| pages << [page, rows.pluck('id')] }

      expect(pages).to eq [[1, [1, 2]], [2, [3]]]
    end

    it 'stops rather than loop when the server ignores ?page=' do
      stubs.get('/things.json') { json([{ 'id' => 1 }]) }

      expect { client.each_site_page('/things.json') { |_rows, _page| nil } }
        .to raise_error(described_class::Aborted, /same page twice/)
    end

    it 'treats a 404 after the first page as the end of the list' do
      stubs.get('/things.json') do |env|
        env.params['page'] == '1' ? json([{ 'id' => 1 }]) : [404, {}, '']
      end

      pages = []
      client.each_site_page('/things.json') { |rows, _page| pages << rows }

      expect(pages.size).to eq 1
    end

    it 'can be limited to max_pages' do
      stubs.get('/things.json') { |env| json([{ 'id' => env.params['page'].to_i }]) }

      pages = []
      client.each_site_page('/things.json', max_pages: 1) { |rows, _page| pages << rows }

      expect(pages.size).to eq 1
    end
  end
end
