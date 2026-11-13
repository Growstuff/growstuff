# frozen_string_literal: true

require 'rails_helper'

describe PostsHelper do
  describe '#post_excerpt' do
    subject(:excerpt) { helper.post_excerpt(post, length: 80) }

    let(:post) { build_stubbed(:post, body:) }
    let(:body) { "I don't recognize **these plants** & their leaves." }

    it 'returns plain text without encoded punctuation' do
      expect(excerpt).to eq 'I don’t recognize these plants & their leaves.'
    end

    context 'with HTML entities in the body' do
      let(:body) { 'I don&#39;t recognize &quot;these&quot; &amp; those plants.' }

      it 'decodes entities' do
        expect(excerpt).to eq 'I don\'t recognize "these" & those plants.'
      end
    end

    context 'with a long body' do
      let(:body) { 'plant ' * 30 }

      it 'limits the excerpt length' do
        expect(excerpt.length).to eq 80
      end
    end

    context 'with encoded HTML' do
      let(:body) { '&lt;script&gt;alert(1)&lt;/script&gt;' }

      it 'leaves decoded text unsafe for HTML rendering' do
        expect(excerpt).not_to be_html_safe
      end
    end
  end
end
