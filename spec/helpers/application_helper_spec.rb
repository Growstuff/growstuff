# frozen_string_literal: true

require 'rails_helper'

describe ApplicationHelper do
  it "parses dates" do
    parse_date(nil).should be_nil
    parse_date('').should be_nil
    parse_date('2012-05-12').should eq Date.new(2012, 5, 12)
    parse_date('may 12th 2012').should eq Date.new(2012, 5, 12)
  end

  describe '#avatar_uri' do
    context 'with a normal user' do
      before do
        @member = FactoryBot.build(:member, email: 'example@example.com', preferred_avatar_uri: nil)
      end

      it 'renders a gravatar uri' do
        expect(avatar_uri(@member)).to eq 'https://secure.gravatar.com/avatar/23463b99b62a72f26ed677cc556c44e8?size=150&default=identicon'
      end

      it 'renders a gravatar uri for a given size' do
        expect(avatar_uri(@member, 456)).to eq 'https://secure.gravatar.com/avatar/23463b99b62a72f26ed677cc556c44e8?size=456&default=identicon'
      end
    end

    context 'with a user who specified a preferred avatar uri' do
      before do
        @member = FactoryBot.build(:member, email: 'example@example.com', preferred_avatar_uri: 'http://media.catmoji.com/post/ujg/cat-in-hat.jpg')
      end

      it 'renders a the specified uri' do
        expect(avatar_uri(@member)).to eq 'http://media.catmoji.com/post/ujg/cat-in-hat.jpg'
      end
    end
  end

  describe '#localize_plural' do
    let(:post) { create(:post) }

    context 'with a populated collection' do
      context 'with one element' do
        before { create(:comment, post:) }

        it 'returns a string with the quantity and the plural of the model' do
          expect(localize_plural(post.comments, Comment)).to eq '1 comment'
        end
      end

      context 'with more than one element' do
        before { create_list(:comment, 2, post:) }

        it 'returns a string with the quantity and the plural of the model' do
          expect(localize_plural(post.comments, Comment)).to eq '2 comments'
        end
      end
    end

    context 'without a populated collection' do
      it 'returns a string with the quantity and the plural of the model' do
        expect(localize_plural(post.comments, Comment)).to eq '0 comments'
      end
    end

    describe '#build_alert_classes' do
      context 'danger' do
        it 'works when :alert' do
          expect(build_alert_classes(:alert)).to include 'alert-danger'
        end

        it 'works when :danger' do
          expect(build_alert_classes(:danger)).to include 'alert-danger'
        end

        it 'works when :error' do
          expect(build_alert_classes(:error)).to include 'alert-danger'
        end

        it 'works when :validation_errors' do
          expect(build_alert_classes(:validation_errors)).to include 'alert-danger'
        end

        it 'includes base classes' do
          expect(build_alert_classes(:danger)).to include 'alert alert-dismissable'
        end

        it 'does not include danger when info' do
          expect(build_alert_classes(:info)).not_to include ' alert-danger'
        end
      end

      context 'warning' do
        it 'works when :warning' do
          expect(build_alert_classes(:warning)).to include 'alert-warning'
        end

        it 'works when :todo' do
          expect(build_alert_classes(:todo)).to include 'alert-warning'
        end

        it 'includes base classes' do
          expect(build_alert_classes(:warning)).to include 'alert alert-dismissable'
        end

        it 'does not include warning when info' do
          expect(build_alert_classes(:info)).not_to include ' alert-warning'
        end
      end

      context 'success' do
        it 'works when :notice' do
          expect(build_alert_classes(:notice)).to include 'alert-success'
        end

        it 'works when :success' do
          expect(build_alert_classes(:success)).to include 'alert-success'
        end

        it 'includes base classes' do
          expect(build_alert_classes(:success)).to include 'alert alert-dismissable'
        end

        it 'does not include success when info' do
          expect(build_alert_classes(:info)).not_to include ' alert-success'
        end
      end

      context 'info' do
        it 'works when :info' do
          expect(build_alert_classes(:info)).to include 'alert-info'
        end

        it 'works when blank' do
          expect(build_alert_classes).to include 'alert-info'
        end

        it 'includes base classes' do
          expect(build_alert_classes(:info)).to include 'alert alert-dismissable'
        end

        it 'does not include info when danger' do
          expect(build_alert_classes(:danger)).not_to include ' alert-info'
        end
      end
    end
  end
end
