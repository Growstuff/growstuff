class CsvImporter
  # used by db/seeds.rb and rake growstuff:import_crops
  # CSV fields:
  # - name (required)
  # - en_wikipedia_url (required)
  # - parent (name, optional)
  # - scientific name (optional, can be picked up from parent if it has one)
  def import_crop(row)
    name, en_wikipedia_url, parent_name, scientific_names, alternate_names = row

    @crop = Crop.find_or_create_by(name: name)
    @crop.update_attributes(
      en_wikipedia_url: en_wikipedia_url,
      creator_id: cropbot.id
    )

    add_parent(parent_name) if parent_name
    add_scientific_names(scientific_names)
    add_alternate_names(alternate_names)
    @crop.save!
    @crop
  end

  private

  def add_parent(parent_name)
    parent = Crop.find_by(name: parent_name)
    if parent
      @crop.update_attributes(parent_id: parent.id)
    else
      @crop.logger.warn("Warning: parent crop #{parent_name} not found")
    end
  end

  def add_scientific_names(scientific_names)
    names_to_add = []
    if scientific_names.present? # i.e. we actually passed something in, which isn't a given
      names_to_add = scientific_names.split(/,\s*/)
    elsif @crop.parent && !@crop.parent.scientific_names.empty? # pick up from parent
      names_to_add = @crop.parent.scientific_names.map(&:name)
    else
      @crop.logger.warn("Warning: no scientific name (not even on parent crop) for #{self}")
    end

    return if names_to_add.empty?

    names_to_add.each do |name|
      sciname = ScientificName.find_by(name: name, crop: @crop)
      sciname ||= ScientificName.create!(name: name, crop: @crop, creator: cropbot)
      @crop.scientific_names << sciname
    end
  end

  def add_alternate_names(alternate_names)
    # i.e. we actually passed something in, which isn't a given
    return if alternate_names.blank?
    alternate_names.split(/,\s*/).each do |name|
      altname = AlternateName.find_by(name: name, crop: @crop)
      altname ||= AlternateName.create! name: name, crop: @crop, creator: cropbot
      @crop.alternate_names << altname
    end
  end

  def cropbot
    @cropbot ||= Member.find_by!(login_name: 'cropbot')
    @cropbot
  rescue StandardError
    raise "cropbot account not found: run rake db:seed"
  end
end
