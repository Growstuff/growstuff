# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserBehaviourDetectionService, type: :service do
  subject(:service) { described_class.new(member) }

  let(:member) { create(:member, confirmed_at: Time.current, bio: 'A friendly gardener') }

  describe '#email_confirmed?' do
    context 'when the member is confirmed' do
      it 'returns true' do
        expect(service.email_confirmed?).to be true
      end
    end

    context 'when the member is unconfirmed' do
      let(:member) { create(:member, confirmed_at: nil) }

      it 'returns false' do
        expect(service.email_confirmed?).to be false
      end
    end
  end

  describe '#bio_present?' do
    context 'when bio is present' do
      it 'returns true' do
        expect(service.bio_present?).to be true
      end
    end

    context 'when bio is blank' do
      let(:member) { create(:member, bio: nil) }

      it 'returns false' do
        expect(service.bio_present?).to be false
      end
    end
  end

  describe '#posts_present?' do
    context 'without posts' do
      it 'returns false' do
        expect(service.posts_present?).to be false
      end
    end

    context 'with posts' do
      before do
        create(:post, author: member)
      end

      it 'returns true' do
        expect(service.posts_present?).to be true
      end
    end
  end

  describe '#comments_present?' do
    context 'without comments' do
      it 'returns false' do
        expect(service.comments_present?).to be false
      end
    end

    context 'with comments' do
      let(:post_record) { create(:post) }

      before do
        create(:comment, author: member, commentable: post_record)
      end

      it 'returns true' do
        expect(service.comments_present?).to be true
      end
    end
  end

  describe '#detected_spam_keywords' do
    context 'without spam keywords' do
      it 'returns an empty array' do
        expect(service.detected_spam_keywords).to be_empty
      end
    end

    context 'with spam keywords in the bio' do
      let(:member) { create(:member, bio: 'Check out our top sports betting sites!') }

      it 'detects sports betting' do
        expect(service.detected_spam_keywords).to include('sports betting')
      end
    end

    context 'with spam keywords in a post subject or body' do
      before do
        create(:post, author: member, subject: 'Best Online Casino Review', body: 'Visit us now')
      end

      it 'detects casino' do
        expect(service.detected_spam_keywords).to include('casino')
      end
    end

    context 'with spam keywords in a comment body' do
      let(:post_record) { create(:post) }

      before do
        create(:comment, author: member, commentable: post_record, body: 'Buy cheap crypto now')
      end

      it 'detects crypto and buy cheap' do
        expect(service.detected_spam_keywords).to include('crypto', 'buy cheap')
      end
    end
  end

  describe '#score' do
    context 'when member is confirmed and has no spam keywords' do
      it 'returns 0' do
        expect(service.score).to eq(0)
      end
    end

    context 'when member is unconfirmed' do
      let(:member) { create(:member, confirmed_at: nil, bio: 'Just growing tomatoes') }

      it 'penalizes unconfirmed email' do
        expect(service.score).to eq(25)
      end
    end

    context 'when member is unconfirmed and has spam keywords' do
      let(:member) { create(:member, confirmed_at: nil, bio: 'Play at the best sports betting platform') }

      it 'combines penalties up to 100' do
        # 25 (unconfirmed) + 50 (sports betting, betting) + 15 (extra keyword) = 90
        expect(service.score).to be >= 75
      end
    end
  end

  describe '.score_for' do
    it 'delegates to instance score' do
      expect(described_class.score_for(member)).to eq(0)
    end
  end
end
