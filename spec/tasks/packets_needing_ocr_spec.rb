# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'packets:needing_ocr' do
  let(:seed) { create(:seed) }
  let(:lines) { output.lines.map { |line| JSON.parse(line) } }
  let(:output) { capture_task }

  def capture_task
    Rake::Task['packets:needing_ocr'].reenable
    original = $stdout
    $stdout = StringIO.new
    Rake::Task['packets:needing_ocr'].invoke
    $stdout.string
  ensure
    $stdout = original
  end

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?('packets:needing_ocr')
  end

  context 'with a back and a front, added back first' do
    let!(:back) { create(:photo, owner: seed.owner).tap { |photo| seed.photo_associations.create!(photo:, label: 'back') } }
    let!(:front) { create(:photo, owner: seed.owner).tap { |photo| seed.photo_associations.create!(photo:, label: 'front') } }

    it('lists the oldest photo first') { expect(lines.pluck('photo_id')).to eq [back.id.to_s, front.id.to_s] }
    it('says which side each is') { expect(lines.pluck('label')).to eq %w(back front) }
    it('says which seed') { expect(lines.first['seed_ids']).to eq [seed.id] }
    it('gives the address of the image') { expect(lines.first['image_url']).to eq back.fullsize_url }
  end

  context 'with a photo that is not of the packet' do
    before { seed.photo_associations.create!(photo: create(:photo, owner: seed.owner)) }

    it('lists nothing') { expect(lines).to be_empty }
  end

  context 'with a packet photo whose seed already has its text' do
    let(:seed) { create(:seed, packet_text: 'Sow by: December 2026') }

    before { seed.photo_associations.create!(photo: create(:photo, owner: seed.owner), label: 'back') }

    it('lists nothing') { expect(lines).to be_empty }
  end

  context 'with a limit' do
    before do
      2.times { seed.photo_associations.create!(photo: create(:photo, owner: seed.owner), label: nil) }
      create(:photo, owner: seed.owner).tap { |photo| seed.photo_associations.create!(photo:, label: 'front') }
      other = create(:seed, owner: seed.owner)
      create(:photo, owner: seed.owner).tap { |photo| other.photo_associations.create!(photo:, label: 'back') }
      stub_const('ENV', ENV.to_hash.merge('LIMIT' => '1'))
    end

    it('lists only that many') { expect(lines.size).to eq 1 }
  end
end
