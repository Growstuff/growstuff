# frozen_string_literal: true

require 'rails_helper'
require 'haml/filters'
require 'tilt'

describe Tilt do
  subject(:rendered) { described_class['md'].new { markdown }.render }

  let(:markdown) { 'plain' }

  it 'is kramdown' do
    expect(described_class['md']).to eq Tilt::KramdownTemplate
  end

  context 'with emphasis' do
    let(:markdown) { '*foo*' }

    it { is_expected.to eq "<p><em>foo</em></p>\n" }
  end

  context 'with a link' do
    let(:markdown) { '[foo](/crops/tomato)' }

    it { is_expected.to include '<a href="/crops/tomato">foo</a>' }
  end

  context 'with a list' do
    let(:markdown) { "* one\n* two" }

    it { is_expected.to include '<li>one</li>' }
  end

  context 'with a fenced code block' do
    let(:markdown) { "~~~\nputs 1\n~~~" }

    it { is_expected.to include '<pre><code>puts 1' }
  end

  context 'with a link to a crop that is not found' do
    let(:markdown) { '[foo](crop)' }

    it { is_expected.to include '<a href="crop">foo</a>' }
  end
end
