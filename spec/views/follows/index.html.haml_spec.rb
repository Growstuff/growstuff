# frozen_string_literal: true

require 'rails_helper'

describe "follows/index" do
  subject { render }

  let(:member) { create(:member) }
  let(:follows) do
    WillPaginate::Collection.create(1, 10, 0) do |pager|
      pager.replace([])
    end
  end

  before do
    allow(controller).to receive(:current_user).and_return(member)
    assign(:member, member)
    assign(:follows, follows)
    render
  end

  it 'renders localized page title' do
    expect(view.content_for(:title)).to eq(
      I18n.t('follows.index.title', member: member.login_name)
    )
  end

  it 'renders localized page title heading' do
    expect(rendered).to have_selector(
      'h1.page-title',
      text: I18n.t('follows.index.title', member: member.login_name)
    )
  end
end
