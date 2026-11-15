# frozen_string_literal: true

# What follows a packet of seed when its crop is changed: the member's own
# plantings sown from it that are still of the old crop, the harvests of those,
# and the seeds saved from those plantings, and so on down. Records of other
# members, or of some other crop, are not touched.
class SeedCropChange
  attr_reader :seed, :from_crop

  def initialize(seed, from_crop)
    @seed = seed
    @from_crop = from_crop
  end

  def plantings = descendants[:plantings]
  def harvests = descendants[:harvests]
  def seeds = descendants[:seeds]

  def any?
    plantings.any? || harvests.any? || seeds.any?
  end

  # Moves them to the seed's crop, all or none of them.
  def apply!
    Seed.transaction do
      # Plantings first: a harvest must be of its planting's crop.
      [plantings, harvests, seeds].each do |records|
        records.each { |record| record.update!(crop: seed.crop) }
      end
    end
  end

  private

  def descendants
    @descendants ||= find_descendants
  end

  def find_descendants
    return { plantings: [], harvests: [], seeds: [] } if from_crop.blank? || from_crop == seed.crop

    found = { plantings: [], harvests: [], seeds: [] }
    seed_ids = [seed.id]
    until seed_ids.empty?
      plantings = of_old_crop(Planting).where(parent_seed_id: seed_ids).where.not(id: found[:plantings]).to_a
      found[:plantings] += plantings
      found[:harvests] += of_old_crop(Harvest).where(planting_id: plantings).where.not(id: found[:harvests]).to_a
      new_seeds = of_old_crop(Seed).where(parent_planting_id: plantings).where.not(id: found[:seeds] + [seed]).to_a
      found[:seeds] += new_seeds
      seed_ids = new_seeds.map(&:id)
    end
    found
  end

  def of_old_crop(model)
    model.where(owner_id: seed.owner_id, crop_id: from_crop.id)
  end
end
