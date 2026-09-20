# frozen_string_literal: true

require 'rails_helper'

describe CropImportService, type: :service do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:connection) { Faraday.new { |f| f.adapter :test, stubs } }
  let(:pages) { {} }
  let(:sleeps) { [] }
  let(:out) { StringIO.new }
  let(:options) do
    { connection: connection, page_size: 2, delay: 1, backoff: 5, reindex: false, out: out,
      sleeper: ->(seconds) { sleeps << seconds } }
  end

  def crop_json(id, name, wikipedia: nil, parent_id: nil)
    resource = {
      id:         id.to_s,
      type:       'crops',
      attributes: {
        name:                           name,
        'en-wikipedia-url':             wikipedia || "https://en.wikipedia.org/wiki/#{name.tr(' ', '_')}",
        perennial:                      false,
        'median-lifespan':              nil,
        'median-days-to-first-harvest': 60,
        'median-days-to-last-harvest':  nil
      }
    }
    resource[:relationships] = { parent: { data: { type: 'crops', id: parent_id.to_s } } } if parent_id
    resource
  end

  # Registers the crops to serve for a page number; unregistered pages come back empty.
  def stub_page(number, crops)
    pages[number] = crops
  end

  # Serves the pages registered with stub_page, following the JSON:API `links.next` convention
  # (an offset-style server that ignores page[number], like production).
  def serve_pages
    stubs.get(CropImportService::CROPS_PATH) do |env|
      index = env.params.dig('page', 'offset').to_i
      links = pages.key?(index + 2) ? { next: "https://example.test#{CropImportService::CROPS_PATH}?page[offset]=#{index + 1}" } : {}
      [200, {}, { data: pages.fetch(index + 1, []), links: links }.to_json]
    end
  end

  around { |example| VCR.turned_off(&example) }

  describe '#call' do
    before { serve_pages }

    it 'imports every page and stops on the first short page' do
      stub_page(1, [crop_json(1, 'achiote'), crop_json(2, 'ackee')])
      stub_page(2, [crop_json(3, 'acorn squash')])

      stats = described_class.new(**options).call

      expect(Crop.pluck(:name)).to contain_exactly('achiote', 'ackee', 'acorn squash')
      expect(stats[:created]).to eq 3
      expect(Crop.find_by(name: 'ackee').median_days_to_first_harvest).to eq 60
    end

    it 'pauses between pages but not after the last one' do
      stub_page(1, [crop_json(1, 'achiote'), crop_json(2, 'ackee')])
      stub_page(2, [crop_json(3, 'acorn squash')])

      described_class.new(**options).call

      expect(sleeps).to eq [1]
    end

    it 'updates existing crops instead of duplicating them' do
      existing = create(:crop, name: 'achiote', perennial: false)
      stub_page(1, [crop_json(1, 'achiote')])

      stats = described_class.new(**options, page_size: 5).call

      expect(Crop.where(name: 'achiote').count).to eq 1
      expect(existing.reload.en_wikipedia_url).to eq 'https://en.wikipedia.org/wiki/achiote'
      expect(stats[:updated]).to eq 1
    end

    it 'skips crops that fail validation and carries on' do
      stub_page(1, [crop_json(1, 'bogus', wikipedia: 'not a url'), crop_json(2, 'ackee')])

      stats = described_class.new(**options).call

      expect(Crop.pluck(:name)).to eq ['ackee']
      expect(stats[:failed]).to eq 1
      expect(out.string).to include('skipped "bogus"')
    end

    it 'follows the next link when the server sends fewer crops than the page size we asked for' do
      stub_page(1, [crop_json(1, 'achiote')])
      stub_page(2, [crop_json(2, 'ackee')])
      stub_page(3, [crop_json(3, 'acorn squash')])

      stats = described_class.new(**options).call

      expect(Crop.pluck(:name)).to contain_exactly('achiote', 'ackee', 'acorn squash')
      expect(stats[:created]).to eq 3
    end

    it 'stops after max_pages' do
      stub_page(1, [crop_json(1, 'achiote'), crop_json(2, 'ackee')])

      described_class.new(**options, max_pages: 1).call

      expect(Crop.count).to eq 2
    end

    it 'links parents that were seen in the same run' do
      stub_page(1, [crop_json(10, 'tomato'), crop_json(11, 'roma tomato', parent_id: 10)])
      stub_page(2, [])

      stats = described_class.new(**options).call

      expect(Crop.find_by(name: 'roma tomato').parent).to eq Crop.find_by(name: 'tomato')
      expect(stats[:parent_not_found]).to eq 0
    end

    it 'counts parents it could not find' do
      stub_page(1, [crop_json(11, 'roma tomato', parent_id: 10)])

      stats = described_class.new(**options).call

      expect(Crop.find_by(name: 'roma tomato').parent).to be_nil
      expect(stats[:parent_not_found]).to eq 1
    end
  end

  describe 'when the server struggles' do
    it 'backs off exponentially, then succeeds' do
      responses = [[503, {}, ''], [503, {}, ''], [200, {}, { data: [crop_json(1, 'achiote')] }.to_json]]
      stubs.get(CropImportService::CROPS_PATH) { responses.shift }

      described_class.new(**options).call

      expect(sleeps).to eq [5, 10]
      expect(Crop.pluck(:name)).to eq ['achiote']
    end

    it 'honours Retry-After, capped at two minutes' do
      responses = [[429, { 'Retry-After' => '3600' }, ''], [200, {}, { data: [] }.to_json]]
      stubs.get(CropImportService::CROPS_PATH) { responses.shift }

      described_class.new(**options).call

      expect(sleeps).to eq [120]
    end

    it 'gives up after max_retries and says where to resume' do
      calls = 0
      stubs.get(CropImportService::CROPS_PATH) do
        calls += 1
        [503, {}, '']
      end

      expect { described_class.new(**options, max_retries: 2).call }
        .to raise_error(CropImportService::Aborted, /Re-running is safe/)
      expect(calls).to eq 3
    end

    it 'does not retry client errors' do
      calls = 0
      stubs.get(CropImportService::CROPS_PATH) do
        calls += 1
        [404, {}, '']
      end

      expect { described_class.new(**options).call }.to raise_error(CropImportService::Aborted, /Not retrying/)
      expect(calls).to eq 1
    end

    it 'retries timeouts' do
      calls = 0
      stubs.get(CropImportService::CROPS_PATH) do
        calls += 1
        raise Faraday::TimeoutError if calls == 1

        [200, {}, { data: [] }.to_json]
      end

      described_class.new(**options).call

      expect(calls).to eq 2
    end

    it 'aborts on a response that is not the expected JSON' do
      stubs.get(CropImportService::CROPS_PATH) { [200, {}, '<html>Application error</html>'] }

      expect { described_class.new(**options).call }.to raise_error(CropImportService::Aborted, /not JSON/)
    end
  end
end
