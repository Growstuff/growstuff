# frozen_string_literal: true

require 'rails_helper'

describe 'layouts/_head.html.haml', type: "view" do
  before do
    render
  end

  it 'has a Posts RSS feed' do
    posts_rss = url_for(controller: 'posts', format: 'rss', only_path: false)
    assert_select "head>link[href='#{posts_rss}']"
  end

  it 'has a Crops RSS feed' do
    crops_rss = url_for(controller: 'crops', format: 'rss', only_path: false)
    assert_select "head>link[href='#{crops_rss}']"
  end

  it 'has a Plantings RSS feed' do
    plantings_rss = url_for(controller: 'plantings', format: 'rss', only_path: false)
    assert_select "head>link[href='#{plantings_rss}']"
  end

  it 'has a title' do
    assert_select "head>title"
  end

  it 'asks for a large social card' do
    assert_select "head>meta[name='twitter:card'][content='summary_large_image']"
  end

  it 'has a 1200 pixel wide og:image' do
    assert_select "head>meta[property='og:image:width'][content='1200']"
  end

  it 'has an og:description' do
    assert_select "head>meta[property='og:description']"
  end
end
