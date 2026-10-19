# frozen_string_literal: true

require 'rails_helper'

describe "posts/_single markdown body" do
  subject(:rendered_post) do
    render partial: "posts/single", locals: { post: }
    rendered
  end

  let(:post) { create(:post, body:) }

  before { controller.stub(:current_user) { nil } }

  context "with bold text" do
    let(:body) { "This is **strong** text" }

    it { is_expected.to include "<strong>strong</strong>" }
  end

  context "with a crop link" do
    let(:crop) { create(:tomato) }
    let(:body) { "Growing [#{crop.name}](crop)" }

    it { is_expected.to include %(<a href="#{crop_path(crop)}">#{crop.name}</a>) }
  end

  context "with an @mention of a member" do
    let(:member) { create(:member) }
    let(:body) { "Thanks @#{member.login_name}" }

    it { is_expected.to include %(<a href="#{member_path(member)}">@#{member.login_name}</a>) }
  end

  context "with raw html" do
    let(:body) { '<script>alert(1)</script>hello' }

    it { is_expected.not_to include "<script>alert(1)</script>" }
  end

  context "with a raw html link" do
    let(:body) { '<a href="http://evil.com">EVIL</a>' }

    it { is_expected.not_to include "evil.com" }
  end
end
