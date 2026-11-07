# frozen_string_literal: true

module CropMergesHelper
  # A crop's name, id and the day it was added: two crops can have the very same
  # name, and the date shows which is older.
  def crop_with_id(crop)
    added = crop.created_at.strftime('%-d %b %Y')
    safe_join([crop.name, content_tag(:small, "##{crop.id} · added #{added}", class: 'text-muted')], ' ')
  end

  # Which of the two crops the merge keeps, by when they were added.
  def merge_age_note(duplicate, target)
    return 'Both were added at the same time.' if duplicate.created_at == target.created_at

    kept = target.created_at < duplicate.created_at ? 'older' : 'newer'
    "You are keeping the #{kept} crop."
  end

  # Something that moves in a merge, as a link to it where it has a page.
  def merge_item(record, duplicate)
    case record
    when Planting, Seed, Harvest then link_to(record.to_s, record)
    when PhotoAssociation then link_to(record.photo.to_s, record.photo)
    when CropPost then link_to(record.post.to_s, record.post)
    when Crop then link_to(crop_with_id(record), record)
    when CropCompanion then merge_companion(record, duplicate)
    else record.name
    end
  end

  private

  def merge_companion(companion, duplicate)
    partner = companion.crop_a_id == duplicate.id ? companion.crop_b : companion.crop_a
    link_to(crop_with_id(partner), partner)
  end
end
