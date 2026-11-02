# frozen_string_literal: true

# Merges a duplicate crop into the crop to keep. Everything that pointed at the
# duplicate (plantings, seeds, harvests, photos, varieties, names and so on)
# moves to the crop being kept, then the duplicate is deleted. Records the keeper
# already has (the same scientific name, say) are not copied, so nothing is
# doubled up.
class CropMerger
  # rubocop:disable Rails/SkipsModelValidations
  class Error < StandardError; end

  attr_reader :duplicate, :target, :member

  def initialize(duplicate, target, member:)
    @duplicate = duplicate
    @target = target
    @member = member
  end

  # What would move, as label => count, for showing before merging.
  def moves
    {
      'Plantings'        => Planting.unscoped.where(crop_id: duplicate.id).count,
      'Seeds'            => Seed.unscoped.where(crop_id: duplicate.id).count,
      'Harvests'         => Harvest.where(crop_id: duplicate.id).count,
      'Photos'           => PhotoAssociation.where(crop_id: duplicate.id).count,
      'Posts'            => CropPost.where(crop_id: duplicate.id).count,
      'Varieties'        => Crop.where(parent_id: duplicate.id).where.not(id: target.id).count,
      'Scientific names' => duplicate.scientific_names.count,
      'Alternate names'  => duplicate.alternate_names.count,
      'Job templates'    => duplicate.crop_job_templates.count
    }
  end

  def merge!
    raise Error, 'Choose two different crops to merge.' if duplicate == target

    Crop.transaction do
      move_varieties
      move_records
      move_names
      move_companions
      move_dismissals
      keep_description
      refresh_counts
      duplicate.reload.destroy!
    end
    target
  end

  private

  # A variety of the duplicate can't become a variety of itself, so if the
  # crop being kept sits under the duplicate it moves up to the duplicate's parent.
  def move_varieties
    target.update_column(:parent_id, duplicate.parent_id) if under_duplicate?
    Crop.where(parent_id: duplicate.id).where.not(id: target.id).update_all(parent_id: target.id)
  end

  def under_duplicate?
    seen = []
    crop = target.parent
    while crop && seen.exclude?(crop.id)
      return true if crop == duplicate

      seen << crop.id
      crop = crop.parent
    end
    false
  end

  def move_records
    [Planting, Seed, Harvest, CropJobTemplate].each do |model|
      model.unscoped.where(crop_id: duplicate.id).update_all(crop_id: target.id)
    end
    move_unique(PhotoAssociation, :photo_id)
    move_unique(CropPost, :post_id)
  end

  # Moves the duplicate's rows whose `column` the target doesn't already have.
  def move_unique(model, column)
    taken = model.where(crop_id: target.id).where.not(column => nil).select(column)
    model.where(crop_id: duplicate.id).where.not(column => taken).update_all(crop_id: target.id)
  end

  def move_names
    move_unique_names(ScientificName)
    move_unique_names(AlternateName)
    add_duplicate_name
  end

  def move_unique_names(model)
    have = model.where(crop_id: target.id).pluck(:name).to_set(&:downcase)
    model.where(crop_id: duplicate.id).find_each do |name|
      model.where(id: name.id).update_all(crop_id: target.id) if have.add?(name.name.downcase)
    end
  end

  # The duplicate's own name still finds the crop it became.
  def add_duplicate_name
    return if duplicate.name.casecmp?(target.name)
    return if AlternateName.where(crop_id: target.id).exists?(['lower(name) = ?', duplicate.name.downcase])

    AlternateName.create!(crop: target, name: duplicate.name, language: 'EN', creator: member)
  end

  def move_companions
    CropCompanion.where(crop_a_id: duplicate.id).or(CropCompanion.where(crop_b_id: duplicate.id)).find_each do |companion|
      crop_a_id = companion.crop_a_id == duplicate.id ? target.id : companion.crop_a_id
      crop_b_id = companion.crop_b_id == duplicate.id ? target.id : companion.crop_b_id
      if crop_a_id == crop_b_id || CropCompanion.exists?(crop_a_id:, crop_b_id:)
        companion.delete
      else
        companion.update_columns(crop_a_id:, crop_b_id:)
      end
    end
  end

  def move_dismissals
    taken = CropDismissal.where(crop_id: target.id).select(:member_id)
    CropDismissal.where(crop_id: duplicate.id).where.not(member_id: taken).update_all(crop_id: target.id)
    CropDismissal.where(crop_id: duplicate.id).delete_all
  end

  def refresh_counts
    Crop.reset_counters(target.id, :plantings, :harvests)
    Crop.where(id: target.id).update_all(photo_associations_count: PhotoAssociation.where(crop_id: target.id).count)
  end

  # The crop being kept keeps its own description; the duplicate's fills a blank one.
  def keep_description
    return if target.description.present? || duplicate.description.blank?

    Crop.where(id: target.id).update_all(description: duplicate.description)
  end
  # rubocop:enable Rails/SkipsModelValidations
end
