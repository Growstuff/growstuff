# frozen_string_literal: true

require 'rails_helper'

describe PaginationHelper do
  subject(:pager) { Pagy::Offset.new(count:, limit: 10, page: 1, request:) }

  let(:count) { 25 }
  let(:request) do
    Pagy::Request.new(request: { base_url: 'http://test.host', path: '/crops', params: {}, cookie: nil })
  end

  describe '#pagination_nav' do
    subject(:nav) { helper.pagination_nav(pager) }

    context 'without a pager' do
      let(:pager) { nil }

      it { is_expected.to be_nil }
    end

    context 'when everything fits on one page' do
      let(:count) { 10 }

      it { is_expected.to be_nil }
    end

    context 'with several pages' do
      it { is_expected.to include 'href="/crops?page=2"' }
    end

    context 'with the Bootstrap pagination classes' do
      it { is_expected.to include 'class="page-link"' }
    end

    context 'when rendered in a view' do
      it { is_expected.to be_html_safe }
    end
  end

  describe '#pagination_info' do
    subject(:info) { helper.pagination_info(pager, noun) }

    let(:noun) { 'crops' }

    it { is_expected.to include 'Displaying crops 1-10 of 25 in total' }

    context 'when the noun contains markup' do
      let(:noun) { '<b>crops</b>' }

      it { is_expected.not_to include '<b>' }
    end
  end
end
