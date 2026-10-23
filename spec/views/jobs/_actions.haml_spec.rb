# frozen_string_literal: true

require 'rails_helper'

describe 'jobs/_actions' do
  let(:job) { create(:job) }

  before { allow(view).to receive(:can?).and_return(true) }

  it 'has Mark as finished on a card, which has no tick box' do
    render partial: 'jobs/actions', locals: { job: }
    expect(rendered).to have_link('Mark as finished', visible: :all)
  end

  it 'has an Edit that goes to the form on a card' do
    render partial: 'jobs/actions', locals: { job: }
    expect(rendered).to have_no_css('a[data-notepad-edit]', visible: :all)
  end
end
