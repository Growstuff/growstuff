# frozen_string_literal: true

require 'rails_helper'

describe DomesticatedAnimal do
  subject(:animal) { build(:domesticated_animal) }

  it 'is valid with the required details' do
    expect(animal).to be_valid
  end

  %i(name species category owner).each do |field|
    it "requires #{field}" do
      animal.public_send("#{field}=", nil)
      expect(animal).not_to be_valid
    end
  end

  it 'rejects an unsupported category' do
    animal.category = 'dragon'
    expect(animal).not_to be_valid
  end

  it 'accepts guinea pigs' do
    animal.category = 'guinea_pig'
    expect(animal).to be_valid
  end

  it 'allows an unspecified biological sex' do
    animal.biological_sex = ''
    expect(animal).to be_valid
  end

  it 'rejects an unsupported biological sex' do
    animal.biological_sex = 'invalid'
    expect(animal).not_to be_valid
  end

  it 'rejects death before birth' do
    animal.assign_attributes(date_of_birth: Date.new(2024, 5, 2), date_of_death: Date.new(2024, 5, 1))
    expect(animal).not_to be_valid
  end

  it 'accepts death on the birth date' do
    animal.assign_attributes(date_of_birth: Date.new(2024, 5, 2), date_of_death: Date.new(2024, 5, 2))
    expect(animal).to be_valid
  end

  context 'with a saved animal' do
    subject(:animal) { create(:domesticated_animal) }

    it 'links a photo belonging to its owner' do
      photo = create(:photo, owner: animal.owner)
      animal.photos << photo
      expect(photo.domesticated_animals).to contain_exactly(animal)
    end

    it 'rejects a photo belonging to someone else' do
      association = animal.photo_associations.build(photo: create(:photo))
      expect(association).not_to be_valid
    end

    it 'is hidden when its owner is discarded' do
      animal.owner.discard
      expect(described_class.find_by(id: animal.id)).to be_nil
    end

    it 'is destroyed with its owner' do
      id = animal.id
      animal.owner.destroy!
      expect(described_class.find_by(id:)).to be_nil
    end

    it 'keeps jobs when deleted', flipper: :domesticated_animals do
      job = create(:job, owner: animal.owner, jobbable: animal)
      animal.destroy!
      expect(job.reload.jobbable).to be_nil
    end
  end
end
