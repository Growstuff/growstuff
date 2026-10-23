# frozen_string_literal: true

require 'rails_helper'

describe 'posts/index.rss.haml', type: "view" do
  subject(:rendered_feed) do
    assign(:posts, [post])
    render
    rendered
  end

  let(:post) { create(:post, body:) }

  before { allow(controller).to receive(:current_user).and_return(nil) }

  context "with bold text" do
    let(:body) { "This is **strong** text" }

    it { is_expected.to include "&lt;strong&gt;strong&lt;/strong&gt;" }
  end

  context "with a crop link" do
    let(:crop) { create(:tomato) }
    let(:body) { "Growing [#{crop.name}](crop)" }

    it { is_expected.to include "&lt;a href=&quot;#{crop_path(crop)}&quot;&gt;#{crop.name}&lt;/a&gt;" }
  end

  context "with raw html" do
    let(:body) { '<script>alert(1)</script>hello' }

    it { is_expected.not_to include "&lt;script" }
  end
end
