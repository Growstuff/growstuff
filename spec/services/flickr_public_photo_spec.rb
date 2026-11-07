# frozen_string_literal: true

require 'rails_helper'

describe FlickrPublicPhoto do
  describe '.photo_id' do
    {
      'https://www.flickr.com/photos/someone/12345/'            => '12345',
      'https://www.flickr.com/photos/someone/12345/in/album-1/' => '12345',
      'https://flic.kr/p/2'                                     => '1',
      'https://example.com/photos/someone/12345/'               => nil,
      'not a url'                                               => nil
    }.each do |url, id|
      it("reads #{url}") { expect(described_class.photo_id(url)).to eq id }
    end
  end

  describe '#attributes' do
    subject(:attributes) { described_class.new('https://www.flickr.com/photos/someone/12345/').attributes }

    let(:photos) { double(:photos, getInfo: info, licenses: double(:licenses, getInfo: licences)) } # rubocop:disable RSpec/VerifiedDoubles
    let(:flickr) { double(:flickr, photos: photos) } # rubocop:disable RSpec/VerifiedDoubles
    let(:info) do
      Struct.new(:id, :title, :license, :visibility, :dates, :owner, :farm, :server, :secret, :originalsecret)
        .new('12345', 'A tomato', '4', Struct.new(:ispublic).new(1), Struct.new(:taken).new('2020-01-02 03:04:05'),
             Struct.new(:nsid, :realname, :username).new('1@N01', 'Pat Photo', 'pat'), 66, '1', 'abc', nil)
    end
    let(:licences) { [Struct.new(:id, :name, :url).new('4', 'Attribution License', 'https://creativecommons.org/licenses/by/2.0/')] }

    before do
      allow(described_class).to receive(:flickr).and_return(flickr)
    end

    it { expect(attributes[:license_name]).to eq 'Attribution License' }
    it { expect(attributes[:author_name]).to eq 'Pat Photo' }
    it { expect(attributes[:source_id]).to eq '12345' }

    context 'when all rights reserved' do
      before { info.license = '0' }

      it { expect { attributes }.to raise_error(described_class::Rejected) { |e| expect(e.reason).to eq :not_creative_commons } }
    end

    context 'when not public' do
      before { info.visibility = Struct.new(:ispublic).new(0) }

      it { expect { attributes }.to raise_error(described_class::Rejected) { |e| expect(e.reason).to eq :not_public } }
    end
  end
end
