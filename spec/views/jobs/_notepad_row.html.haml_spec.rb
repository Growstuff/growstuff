# frozen_string_literal: true

require 'rails_helper'

describe 'jobs/_notepad_row' do
  let(:job) { create(:job, name: 'Net the berries') }

  before do
    allow(view).to receive(:can?).and_return(true)
    render partial: 'jobs/notepad_row', locals: { job: }
  end

  it 'shows the name' do
    expect(rendered).to have_css('.notepad-name', text: 'Net the berries')
  end

  it 'has a menu Edit that the script edits in place' do
    expect(rendered).to have_css('a[data-notepad-edit]', text: 'Edit', visible: :all)
  end

  it 'still has the form page for Edit, when the script cannot' do
    expect(rendered).to have_link('Edit', href: edit_job_path(job), visible: :all)
  end

  context 'with a garden' do
    let(:job) { create(:job, garden: create(:garden, name: 'Berries garden')) }

    it 'shows the garden, on the jobs page' do
      expect(rendered).to have_css('.notepad-chip.garden', text: 'Berries garden')
    end

    it 'does not repeat the garden, when shown on that garden\'s own page' do
      on_gardens_page = view.render(partial: 'jobs/notepad_row', locals: { job:, in_garden: true })
      expect(Capybara.string(on_gardens_page)).to have_no_css('.notepad-chip.garden')
    end
  end

  context 'when crossed off' do
    let(:job) { create(:job, due_date: Date.new(2020, 1, 6), finished: true) }

    it 'shows when it was crossed off, not when it was due' do
      expect(rendered).to have_css('.notepad-due', text: /\Adone /)
    end
  end

  %w(before after).each do |moment|
    it "has a menu item for a #{moment} photo, which opens the add-photo dialog" do
      link = "a[href='#{new_photo_path(id: job.id, type: 'job', moment:)}'][data-photo-dialog]"
      expect(rendered).to have_css(link, text: "Add a#{'n' if moment == 'after'} #{moment} photo", visible: :all)
    end
  end

  it 'shows no photos for a job that has none' do
    expect(rendered).to have_no_css('.notepad-photo')
  end

  context 'with a before and an after photo' do
    let(:job) do
      create(:job).tap do |job|
        job.photo_associations.create!(photo: create(:photo, owner: job.owner, title: 'Net on'), moment: 'before')
        job.photo_associations.create!(photo: create(:photo, owner: job.owner, title: 'Net off'), moment: 'after')
      end
    end

    it 'shows both' do
      expect(rendered).to have_css('.notepad-photo', count: 2)
    end

    it 'says which is which' do
      expect(rendered).to have_css('.notepad-photo', text: 'Before').and have_css('.notepad-photo', text: 'After')
    end

    it 'links each to its photo' do
      photo = job.photo_at('before')
      expect(rendered).to have_link(href: photo_path(photo), title: 'Before photo: Net on')
    end
  end

  it 'has no Mark as finished in its menu, as it has a tick box' do
    expect(rendered).to have_no_link('Mark as finished', visible: :all)
  end

  it 'has a hint for editing, hidden until then' do
    expect(rendered).to have_css('.notepad-edit-hint[hidden]', text: 'Enter to save', visible: :all)
  end
end
