# frozen_string_literal: true

require 'rails_helper'

describe 'crops/_post' do
  subject(:row) { Capybara.string(rendered) }

  let(:post) { build_stubbed(:post, body: 'I don&#39;t recognize **these plants**.') }
  let(:photo) { nil }

  before do
    allow(post).to receive(:default_photo).and_return(photo)
    render partial: 'crops/post', locals: { post: }
  end

  it 'renders readable excerpt text' do
    expect(row.find('.post-body').text).to eq "I don't recognize these plants."
  end

  it 'links the call to action to the post' do
    expect(row).to have_css(".crop-post-action a[href='#{post_path(post)}']")
  end

  context 'without a photo' do
    it 'omits the thumbnail' do
      expect(row).to have_no_css('.crop-post-thumbnail')
    end
  end

  context 'with a photo' do
    let(:photo) { build_stubbed(:photo) }

    it 'renders a thumbnail' do
      expect(row).to have_css(".crop-post-thumbnail img[src='#{photo.thumbnail_url}']")
    end
  end
end
