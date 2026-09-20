# frozen_string_literal: true

# Copies one member's gardens, plantings and planting photos from another
# Growstuff instance (production by default) into the local database.
# Network gentleness lives in RemoteApiClient.
#
# Uses the site's own JSON (/members/x/gardens.json and friends), which carries
# every column, rather than the JSON:API, whose gardens only expose a name and
# whose related-resource endpoints return the wrong records.
#
# What comes across:
# * the member (created locally if missing, with a throwaway password)
# * their gardens, with location, coordinates and description
# * their plantings, and just the crops those plantings use (fetched one by
#   one, so there is no need to pull every crop first)
# * photos on those plantings. Flickr photos are stored the way production
#   stores them: as records pointing at Flickr's own image URLs, so nothing is
#   downloaded from Flickr. (The site has no way to list a garden's photos.)
#
# Re-running is safe: gardens and plantings are matched by slug and photos by
# image URL.
class MemberImportService
  class Aborted < StandardError; end

  # rubocop:disable-next Metrics/ParameterLists
  def initialize(login_name:, local_email: nil, local_password: nil, photos: true, out: $stdout, client: nil,
    **client_options)
    @login_name = login_name
    @local_email = local_email
    @local_password = local_password
    @photos = photos
    @out = out
    @client = client || RemoteApiClient.new(out: out, **client_options)
    @crop_importer = CropImportService.new(client: @client, out: out, reindex: false)
    @stats = Hash.new(0)
    @crops_by_remote_id = {}
  end

  def call
    remote_member = find_remote_member
    @remote_member_id = remote_member['id']
    @member = local_member
    gardens = import_gardens(remote_member)
    import_plantings(remote_member, gardens)
    @stats
  rescue RemoteApiClient::Aborted => e
    raise Aborted, "#{e.message} Nothing is lost: re-running picks up where this left off."
  end

  private

  def find_remote_member
    remote = @client.all('/api/v1/members', 'filter[login_name]' => @login_name)
      .find { |member| member.dig('attributes', 'login-name').to_s.casecmp?(@login_name) }
    raise Aborted, "No member called #{@login_name.inspect} found on the source site." unless remote

    @out.puts "Found #{@login_name} on the source site (member #{remote['id']})"
    remote
  end

  def local_member
    member = Member.find_by(login_name: @login_name) || create_member
    @out.puts "Importing into local member #{member.login_name} (id #{member.id})"
    member
  end

  def create_member
    password = @local_password || SecureRandom.hex(8)
    member = Member.new(login_name: @login_name, email: @local_email || "#{@login_name}@example.invalid".downcase,
                        password: password, tos_agreement: true)
    member.skip_confirmation!
    raise Aborted, "Could not create local member #{@login_name}: #{member.errors.full_messages.to_sentence}" unless member.save

    @stats[:members_created] += 1
    @out.puts "Created local member #{member.login_name}: email #{member.email}, password #{password}"
    member
  end

  # Returns { remote garden id => local Garden }
  def import_gardens(remote_member)
    gardens = {}
    @client.each_site_page("/members/#{remote_member.dig('attributes', 'slug')}/gardens.json", { 'all' => 1 }) do |rows, _page|
      rows.each do |row|
        # The list also includes gardens the member only collaborates on.
        next unless row['owner_id'].to_s == remote_member['id']

        garden = import_garden(row)
        gardens[row['id']] = garden if garden
      end
    end
    gardens
  end

  def import_garden(row)
    garden = Garden.find_or_initialize_by(slug: row['slug'])
    if garden.persisted? && garden.owner_id != @member.id
      return count_failure("garden #{row['name'].inspect}", garden, 'belongs to another member')
    end

    outcome = garden.new_record? ? :gardens_created : :gardens_updated
    garden.assign_attributes(
      owner: @member, name: row['name'].to_s.strip, description: row['description'], active: row['active'],
      location: row['location'], latitude: row['latitude'], longitude: row['longitude'],
      area: row['area'], area_unit: row['area_unit'], location_wikidata_id: row['location_wikidata_id'],
      lowest_temp_c: row['lowest_temp_c'], highest_temp_c: row['highest_temp_c'],
      created_at: row['created_at'], updated_at: row['updated_at']
    )
    # Skips validation, and with it the geocoding and Wikidata lookups that run
    # after it: the coordinates and Wikidata id already came from the source.
    garden.save!(validate: false)

    @stats[outcome] += 1
    @out.puts "garden #{garden.name.inspect} (#{garden.location})"
    garden
  end

  def import_plantings(remote_member, gardens)
    @client.each_site_page("/members/#{remote_member.dig('attributes', 'slug')}/plantings.json", { 'all' => 1 }) do |rows, page|
      rows.each { |row| import_planting(row, gardens) }
      @out.puts "plantings page #{page}: #{rows.size} (#{@stats[:plantings_created]} created so far)"
    end
  end

  def import_planting(row, gardens)
    garden = gardens[row['garden_id']]
    return @stats[:plantings_skipped_garden_not_imported] += 1 unless garden

    crop = find_crop(row['crop_id'])
    return @stats[:plantings_skipped_crop_missing] += 1 unless crop

    planting = save_planting(row, garden, crop)
    import_photos(planting) if planting && @photos
  end

  def save_planting(row, garden, crop)
    planting = Planting.find_or_initialize_by(slug: row['slug'])
    if planting.persisted? && planting.owner_id != @member.id
      return count_failure("planting #{row['slug']}", planting, 'belongs to another member')
    end

    outcome = planting.new_record? ? :plantings_created : :plantings_updated
    planting.assign_attributes(
      owner: @member, garden: garden, crop: crop,
      planted_at: row['planted_at'], quantity: row['quantity'], description: row['description'],
      sunniness: row['sunniness'].presence, planted_from: row['planted_from'].presence,
      failed: row['failed'], finished: row['finished'], finished_at: row['finished_at'],
      overall_rating: row['overall_rating'], created_at: row['created_at']
    )
    return count_failure("planting #{row['slug']}", planting) unless planting.save

    @stats[outcome] += 1
    planting
  end

  # Fetches (once) the crop a planting uses, from the JSON:API, and saves it
  # locally. Only crops that plantings actually use are ever requested.
  def find_crop(remote_crop_id)
    return @crops_by_remote_id[remote_crop_id] if @crops_by_remote_id.key?(remote_crop_id)

    resource = @client.get_resource("/api/v1/crops/#{remote_crop_id}")
    crop = resource && @crop_importer.import_resource(resource)
    @out.puts "crop #{crop.name}" if crop
    @crops_by_remote_id[remote_crop_id] = crop
  end

  # One request per planting; the site cannot tell us which have photos.
  def import_photos(planting)
    @client.each_site_page("/plantings/#{planting.slug}/photos.json", max_pages: 1) do |rows, _page|
      rows.each do |row|
        next unless row['owner_id'].to_s == @remote_member_id

        photo = import_photo(row)
        link_photo(photo, planting) if photo
      end
    end
  end

  def import_photo(row)
    photo = Photo.find_or_initialize_by(fullsize_url: row['fullsize_url'])
    if photo.persisted?
      @stats[:photos_unchanged] += 1
      return photo
    end

    photo.assign_attributes(
      owner: @member, thumbnail_url: row['thumbnail_url'], link_url: row['link_url'], title: row['title'],
      license_name: row['license_name'], license_url: row['license_url'], date_taken: row['date_taken'],
      source: row['source'], source_id: row['source_id'], created_at: row['created_at']
    )
    return count_failure("photo #{row['title'].inspect}", photo) unless photo.save

    @stats[:photos_created] += 1
    photo
  end

  def link_photo(photo, planting)
    association = PhotoAssociation.find_or_initialize_by(photo: photo, photographable: planting)
    return unless association.new_record?

    if association.save
      @stats[:photos_linked] += 1
    else
      count_failure("photo link for planting #{planting.slug}", association)
    end
  end

  def count_failure(what, record, reason = nil)
    @stats[:failed] += 1
    @out.puts "  skipped #{what}: #{reason || record.errors.full_messages.to_sentence}"
    nil
  end
end
