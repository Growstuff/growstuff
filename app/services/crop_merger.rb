# frozen_string_literal: true

# Merges a duplicate crop into the crop to keep. Everything that pointed at the
# duplicate (plantings, seeds, harvests, photos, varieties, names and so on)
# moves to the crop being kept, then the duplicate is deleted. Records the keeper
# already has (the same scientific name, say) are not copied, so nothing is
# doubled up.
class CropMerger
  # rubocop:disable Rails/SkipsModelValidations
  class Error < StandardError; end

  # One kind of record in the plan: the first few that move, how many move in
  # all, and those left behind because the crop being kept already has them.
  Group = Struct.new(:label, :moving, :total, :skipped)

  SHOWN = 25

  attr_reader :duplicate, :target, :member

  def initialize(duplicate, target, member:)
    @duplicate = duplicate
    @target = target
    @member = member
  end

  # What a merge would do, a Group for each kind of record that has any, for
  # showing before merging.
  def plan
    [
      group('Plantings', Planting.unscoped.where(crop_id: duplicate.id).includes(:crop, :garden, :owner)),
      group('Seeds', Seed.unscoped.where(crop_id: duplicate.id).includes(:crop, :owner)),
      group('Harvests', Harvest.where(crop_id: duplicate.id).includes(:crop, :owner, :plant_part)),
      unique_group('Photos', PhotoAssociation, :photo_id, :photo),
      unique_group('Posts', CropPost, :post_id, :post),
      group('Varieties', Crop.where(parent_id: duplicate.id).where.not(id: target.id)),
      names_group('Scientific names', ScientificName),
      names_group('Alternate names', AlternateName),
      group('Job templates', CropJobTemplate.where(crop_id: duplicate.id)),
      companions_group
    ].reject { |group| group.total.zero? && group.skipped.empty? }
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

  def group(label, scope)
    Group.new(label, scope.limit(SHOWN).to_a, scope.count, [])
  end

  def unique_group(label, model, column, includes)
    moving, skipped = unique_rows(model, column)
    Group.new(label, moving.includes(includes).limit(SHOWN).to_a, moving.count, skipped.includes(includes).to_a)
  end

  def names_group(label, model)
    moving, skipped = name_rows(model)
    Group.new(label, moving.first(SHOWN), moving.size, skipped)
  end

  def companions_group
    moving, skipped = companion_rows
    Group.new('Companions', moving.first(SHOWN).map(&:first), moving.size, skipped.map(&:first))
  end

  # The duplicate's rows whose `column` the crop being kept does, and doesn't, already have.
  def unique_rows(model, column)
    taken = model.where(crop_id: target.id).where.not(column => nil).select(column)
    rows = model.where(crop_id: duplicate.id)
    [rows.where.not(column => taken), rows.where(column => taken)]
  end

  # Names the crop being kept lacks, and has (whatever the case), as arrays.
  def name_rows(model)
    have = model.where(crop_id: target.id).pluck(:name).to_set(&:downcase)
    model.where(crop_id: duplicate.id).order(:name).partition { |name| have.add?(name.name.downcase) }
  end

  # The duplicate's companionships as [companion, crop_a_id, crop_b_id] once pointed at the
  # crop being kept: those that move, and those that would pair a crop with itself or repeat one.
  def companion_rows
    seen = Set.new
    repointed = CropCompanion.where(crop_a_id: duplicate.id).or(CropCompanion.where(crop_b_id: duplicate.id))
      .includes(:crop_a, :crop_b).order(:id).map do |companion|
        [companion,
         companion.crop_a_id == duplicate.id ? target.id : companion.crop_a_id,
         companion.crop_b_id == duplicate.id ? target.id : companion.crop_b_id]
      end
    repointed.partition do |_, crop_a_id, crop_b_id|
      crop_a_id != crop_b_id && !CropCompanion.exists?(crop_a_id:, crop_b_id:) && seen.add?([crop_a_id, crop_b_id])
    end
  end

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

  def move_unique(model, column)
    unique_rows(model, column).first.update_all(crop_id: target.id)
  end

  def move_names
    [ScientificName, AlternateName].each do |model|
      moving, = name_rows(model)
      model.where(id: moving.map(&:id)).update_all(crop_id: target.id)
    end
    add_duplicate_name
  end

  # The duplicate's own name still finds the crop it became.
  def add_duplicate_name
    return if duplicate.name.casecmp?(target.name)
    return if AlternateName.where(crop_id: target.id).exists?(['lower(name) = ?', duplicate.name.downcase])

    AlternateName.create!(crop: target, name: duplicate.name, language: 'EN', creator: member)
  end

  def move_companions
    moving, skipped = companion_rows
    moving.each { |companion, crop_a_id, crop_b_id| companion.update_columns(crop_a_id:, crop_b_id:) }
    skipped.each { |companion,| companion.delete }
  end

  def move_dismissals
    taken = CropDismissal.where(crop_id: target.id).select(:member_id)
    CropDismissal.where(crop_id: duplicate.id).where.not(member_id: taken).update_all(crop_id: target.id)
    CropDismissal.where(crop_id: duplicate.id).delete_all
  end

  # The crop being kept keeps its own description; the duplicate's fills a blank one.
  def keep_description
    return if target.description.present? || duplicate.description.blank?

    Crop.where(id: target.id).update_all(description: duplicate.description)
  end

  def refresh_counts
    Crop.reset_counters(target.id, :plantings, :harvests)
    Crop.where(id: target.id).update_all(photo_associations_count: PhotoAssociation.where(crop_id: target.id).count)
  end
  # rubocop:enable Rails/SkipsModelValidations
end
