require 'rails_helper'

describe 'layouts/_meta.html.haml', type: "view" do
  before(:each) do
    render
  end

  it 'should have a Posts RSS feed' do
    posts_rss = url_for(controller: 'posts', format: 'rss', only_path: false)
    assert_select "head>link[href='#{posts_rss}']"
  end

  it 'should have a Crops RSS feed' do
    crops_rss = url_for(controller: 'crops', format: 'rss', only_path: false)
    assert_select "head>link[href='#{crops_rss}']"
  end

  it 'should have a Plantings RSS feed' do
    plantings_rss = url_for(controller: 'plantings', format: 'rss', only_path: false)
    assert_select "head>link[href='#{plantings_rss}']"
  end

  it 'should have a title' do
    assert_select "head>title"
  end
end
