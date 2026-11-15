# frozen_string_literal: true

# What a crop wrangler does with an EcoCrop record: link it to a crop, copying across the common names they
# chose as alternate names, or make a new crop from it.
class EcocropCropLinker
  class Error < StandardError; end

  def initialize(record:, member:)
    @record = record
    @member = member
  end

  # Links the crop and adds the chosen names to it; returns how many names were added.
  def link(crop, names: [])
    Crop.transaction do
      crop.update!(ecocrop_record: @record)
      add_names(crop, names)
    end
  end

  # A new approved crop with the record's scientific name, linked to the record, with the chosen names. An approved
  # crop needs the address of its English Wikipedia page.
  def create_crop(name:, wikipedia_url:, names: [])
    name = name.to_s.squish
    raise Error, :name_blank if name.blank?
    raise Error, :name_taken if Crop.exists?(['lower(name) = ?', name.downcase])

    Crop.transaction do
      crop = Crop.create!(name:, creator: @member, approval_status: 'approved', en_wikipedia_url: wikipedia_url.to_s.strip)
      crop.scientific_names.create!(name: @record.scientificname, creator: @member)
      link(crop, names:)
      crop
    end
  end

  # Only names EcoCrop has, and the crop lacks, are ever added, whatever was asked for.
  def add_names(crop, names)
    wanted = Array(names).map { |name| name.to_s.squish.downcase }
    to_add = @record.new_common_names_for(crop).select { |name| wanted.include?(name.downcase) }
    to_add.each { |name| crop.alternate_names.create!(name:, language: 'EN', creator: @member) }
    to_add.size
  end
end
