# frozen_string_literal: true

require 'rails_helper'

describe Job, '#photo_at' do
  let(:job) { create(:job) }
  let(:before_photo) { create(:photo, owner: job.owner) }
  let(:after_photo) { create(:photo, owner: job.owner) }

  before do
    job.photo_associations.create!(photo: before_photo, moment: 'before')
    job.photo_associations.create!(photo: after_photo, moment: 'after')
    job.photo_associations.create!(photo: create(:photo, owner: job.owner))
  end

  it 'is the photo taken before' do
    expect(job.reload.photo_at('before')).to eq before_photo
  end

  it 'is the photo taken after' do
    expect(job.reload.photo_at('after')).to eq after_photo
  end

  it 'is nothing for a moment with no photo' do
    job.photo_associations.where(moment: 'after').destroy_all
    expect(job.reload.photo_at('after')).to be_nil
  end

  it 'is the first added, when there are several' do
    job.photo_associations.create!(photo: create(:photo, owner: job.owner), moment: 'before')
    expect(job.reload.photo_at('before')).to eq before_photo
  end

  it 'ignores photos with no moment' do
    expect(job.reload.photos.count).to eq 3
  end

  it 'goes with its photos\' links when the job goes' do
    expect { job.destroy }.to change(PhotoAssociation, :count).by(-3)
  end
end
