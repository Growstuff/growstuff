# frozen_string_literal: true

require 'rails_helper'

describe MastodonPhotoSource do
  subject(:source) { described_class.new(authentication, resolver:, adapter: [:test, stubs]) }

  around { |example| VCR.turned_off { example.run } }

  let(:member) { create(:member) }
  let(:authentication) { create(:mastodon_authentication, member:, uid: '111@photos.example') }
  let(:resolver) { class_double(Resolv, getaddresses: addresses) }
  let(:addresses) { ['93.184.216.34'] }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:attachment) do
    { 'id' => '456', 'type' => 'image', 'url' => 'https://cdn.example/full.jpg',
      'preview_url' => 'https://cdn.example/small.jpg', 'description' => 'Tomatoes ripening' }
  end
  let(:status) do
    { 'id' => '123', 'account' => { 'id' => '111' }, 'visibility' => 'public', 'sensitive' => false,
      'url' => 'https://photos.example/@alice/123', 'media_attachments' => [attachment] }
  end
  let(:statuses) { [status] }
  let(:list_body) { statuses.to_json }
  let(:response_status) { 200 }
  let(:sent) { [] }

  before do
    stubs.get('/api/v1/accounts/111/statuses') do |env|
      sent << env
      [response_status, {}, list_body]
    end
    stubs.get('/api/v1/statuses/123') { [response_status, {}, status.to_json] }
  end

  def import(consent: true)
    source.import(status_id: '123', attachment_id: '456', license_accepted: consent)
  end

  describe '#photos' do
    it 'returns hosted image URLs' do
      expect(source.photos[:photos].first[:preview_url]).to eq attachment['url']
    end

    it 'returns the last status as the next cursor' do
      expect(source.photos[:next_cursor]).to eq '123'
    end

    it 'passes the status cursor to the server' do
      source.photos(cursor: '789')
      expect(sent.first.params['max_id']).to eq '789'
    end

    it 'filters by hashtag on the server' do
      source.photos(tag: 'tomatoes')
      expect(sent.first.params['tagged']).to eq 'tomatoes'
    end

    it 'requests no boosts' do
      source.photos
      expect(sent.first.params['exclude_reblogs']).to eq 'true'
    end

    it 'does not send an access token' do
      source.photos
      expect(sent.first.request_headers).not_to have_key('Authorization')
    end

    it 'requires a licence for new images' do
      expect(source.photos[:photos].first[:license_name]).to be_nil
    end

    context 'with multiple images on a post' do
      before { status['media_attachments'] << attachment.merge('id' => '457', 'url' => 'https://cdn.example/other.jpg') }

      it 'offers each image separately' do
        expect(source.photos[:photos].pluck(:id)).to eq %w(456 457)
      end
    end

    context 'without a thumbnail' do
      before { attachment['preview_url'] = nil }

      it 'uses the hosted fullsize image' do
        expect(source.photos[:photos].first[:thumb_url]).to eq attachment['url']
      end
    end

    context 'without results' do
      let(:statuses) { [] }

      it 'ends pagination' do
        expect(source.photos[:next_cursor]).to be_nil
      end
    end

    context 'with only ineligible attachments' do
      before { attachment['type'] = 'video' }

      it 'keeps pagination available' do
        expect(source.photos[:next_cursor]).to eq '123'
      end
    end
  end

  describe '#import' do
    it 'does not save before the controller transaction' do
      expect(import).to be_new_record
    end

    it 'qualifies the attachment identity by server' do
      expect(import.source_id).to eq '456@photos.example'
    end

    it 'uses the original hosted image' do
      expect(import.fullsize_url).to eq attachment['url']
    end

    it 'links to the parent post' do
      expect(import.link_url).to eq status['url']
    end

    it 'preserves the image description' do
      expect(import.title).to eq attachment['description']
    end

    it 'does not mistake the posting date for the date taken' do
      expect(import.date_taken).to be_nil
    end

    it 'records the agreed licence' do
      expect(import.license_name).to eq 'CC BY-SA 4.0'
    end

    it 'records the agreed licence URL' do
      expect(import.license_url).to eq described_class::LICENSE_URL
    end

    [nil, false, '0', 'false', ''].each do |consent|
      context "with #{consent.inspect} for licence consent" do
        it 'rejects the import' do
          expect { import(consent:) }.to raise_error(described_class::Rejected, 'license_required')
        end
      end
    end

    context 'with an image already imported by this member' do
      let!(:photo) { create(:photo, owner: member, source: 'mastodon', source_id: '456@photos.example', license_name: 'CC BY 4.0') }

      it 'reuses the existing record' do
        expect(import(consent: false).id).to eq photo.id
      end

      it 'keeps its stated licence' do
        expect(import(consent: false).license_name).to eq 'CC BY 4.0'
      end

      it 'offers its stated licence in the picker' do
        expect(source.photos[:photos].first[:license_name]).to eq 'CC BY 4.0'
      end
    end

    context 'with the same attachment id on another server' do
      before { create(:photo, owner: member, source: 'mastodon', source_id: '456@other.example') }

      it 'does not reuse the other server image' do
        expect(import).to be_new_record
      end
    end

    context 'with an attachment not on the selected post' do
      before { status['media_attachments'] = [] }

      it 'rejects the import' do
        expect { import }.to raise_error(described_class::Rejected)
      end
    end
  end

  {
    'a private post'    => { 'visibility' => 'private' },
    'an unlisted post'  => { 'visibility' => 'unlisted' },
    'a direct post'     => { 'visibility' => 'direct' },
    'a sensitive post'  => { 'sensitive' => true },
    'a content warning' => { 'spoiler_text' => 'Warning' },
    'a boost'           => { 'reblog' => { 'id' => '999' } },
    'another account'   => { 'account' => { 'id' => '222' } }
  }.each do |situation, changes|
    context "with #{situation}" do
      before { status.merge!(changes) }

      it 'does not offer the image' do
        expect(source.photos[:photos]).to be_empty
      end

      it 'rejects a direct import' do
        expect { import }.to raise_error(described_class::Rejected)
      end
    end
  end

  context 'with a missing image URL' do
    before { attachment['url'] = nil }

    it 'does not offer the image' do
      expect(source.photos[:photos]).to be_empty
    end
  end

  context 'with a malformed account in the response' do
    before { status['account'] = 'unexpected' }

    it 'does not offer the image' do
      expect(source.photos[:photos]).to be_empty
    end
  end

  context 'with an unexpected list response' do
    let(:statuses) { { error: 'not a list' } }

    it 'rejects the response' do
      expect { source.photos }.to raise_error(described_class::Rejected)
    end
  end

  context 'with an invalid JSON response' do
    let(:list_body) { '<html>Maintenance</html>' }

    it 'reports the server unavailable' do
      expect { source.photos }.to raise_error(described_class::Rejected, 'unavailable')
    end
  end

  context 'with a server name containing a path' do
    before { authentication.uid = ['111', 'photos.example/private'].join('@') }

    it 'rejects the server before making a request' do
      expect { source.photos }.to raise_error(described_class::Rejected)
    end
  end

  context 'with a DNS failure' do
    before { allow(resolver).to receive(:getaddresses).and_raise(Resolv::ResolvError) }

    it 'reports the server unavailable' do
      expect { source.photos }.to raise_error(described_class::Rejected, 'unavailable')
    end
  end

  context 'with a private server address' do
    let(:addresses) { ['127.0.0.1'] }

    it 'rejects the server before making a request' do
      expect { source.photos }.to raise_error(described_class::Rejected, 'unavailable')
    end
  end

  context 'with a redirect' do
    let(:response_status) { 302 }

    it 'does not follow it' do
      expect { source.photos }.to raise_error(described_class::Rejected, 'unavailable')
    end
  end

  context 'with a rate limit' do
    let(:response_status) { 429 }

    it 'reports the server unavailable' do
      expect { source.photos }.to raise_error(described_class::Rejected, 'unavailable')
    end
  end

  context 'with a response larger than the limit' do
    # Valid JSON, so only the size can make it fail.
    let(:list_body) { "[#{' ' * described_class::MAX_RESPONSE_BYTES}]" }

    it 'reports the server unavailable' do
      expect { source.photos }.to raise_error(described_class::Rejected, 'unavailable')
    end
  end

  context 'with several addresses' do
    subject(:source) { described_class.new(authentication, resolver:, adapter: [:test, address_stubs]) }

    let(:addresses) { %w(93.184.216.34 93.184.216.35) }
    let(:address_stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        first_address.each { |reply| stub.get('/api/v1/accounts/111/statuses', &reply) }
        stub.get('/api/v1/accounts/111/statuses') { [200, {}, list_body] }
      end
    end

    context 'when the first cannot be reached' do
      let(:first_address) { [-> { raise Faraday::ConnectionFailed, 'no route' }] }

      it 'uses the next one' do
        expect(source.photos[:photos].size).to eq 1
      end
    end

    context 'when the first is reached but fails' do
      let(:first_address) { [-> { [500, {}, ''] }] }

      it 'does not try the next one' do
        expect { source.photos }.to raise_error(described_class::Rejected, 'unavailable')
      end
    end

    context 'when none can be reached' do
      let(:address_stubs) do
        Faraday::Adapter::Test::Stubs.new { |stub| stub.get('/api/v1/accounts/111/statuses') { raise Faraday::ConnectionFailed, 'no route' } }
      end

      it 'reports the server unavailable' do
        expect { source.photos }.to raise_error(described_class::Rejected, 'unavailable')
      end
    end
  end

  context 'with an invalid cursor' do
    it 'does not let a cursor change the request URL' do
      expect { source.photos(cursor: '../other') }.to raise_error(described_class::Rejected)
    end
  end
end
