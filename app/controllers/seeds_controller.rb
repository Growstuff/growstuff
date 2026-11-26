# frozen_string_literal: true

class SeedsController < DataController
  GROUPINGS = %w(crop source year use_by heirloom gardener).freeze
  PER_PAGE = 30 # piles of packets on a page of the web page, seeds in the data formats
  NO_USE_BY = 'no use-by date'
  SEED_LIBRARY_HEADER = 'X-Seed-Library'

  def index
    @seeds = Seed.all

    if params[:member_slug].present?
      @owner = Member.find_by!(slug: params[:member_slug])
      @seeds = @seeds.where(owner_id: @owner.id)
    end

    if params[:crop_slug].present?
      @crop = Crop.find_by(slug: params[:crop_slug])
      @seeds = @seeds.of_crop(@crop) if @crop
    end

    if params[:planting_id].present?
      @planting = Planting.find_by(slug: params[:planting_id])
      @seeds = @seeds.where(parent_planting_id: @planting.id) if @planting
    end

    @seeds = filter(@seeds)
    @filtered = Seed::FILTER_PARAMS.any? { |name| params[name].present? }

    # Searching is by choosing a crop, so there is only ever a real one to offer.
    @search_crop = Crop.find_by(slug: params[:crop]) if params[:crop].present? && @crop.blank?
    @seeds = @seeds.of_crop(@search_crop) if @search_crop

    @owned_crop_ids = current_member ? current_member.seeds.current.pluck(:crop_id) : []
    @past_count = @seeds.current.expired.count
    @seeds = @seeds.expired if params[:past] == '1'

    @in_stock_count = @seeds.current.count
    @finished_count = @seeds.finished.count
    @show_finished = (params[:finished] == '1')
    @other_count = @show_finished ? @in_stock_count : @finished_count
    @show_all = (params[:all] == '1')
    @seeds = if @show_all then @seeds
             elsif @show_finished then @seeds.finished
             else @seeds.current
             end
    @stats = library_stats(@owner) if @owner
    @seed_total = @seeds.count
    @shared_totals = { packets: @seed_total, gardeners: @seeds.distinct.count(:owner_id) } if @everyone

    @filename = csv_filename
    @sort_by_distance = @crop.present? && current_member&.latitude.present? && current_member&.longitude.present?
    @seeds = @seeds.includes({ crop: :parent }, :owner)
    @seeds = @sort_by_distance ? order_by_distance(@seeds, current_member) : @seeds.order(created_at: :desc)
    if page_of_piles?
      @seeds, @piles = paginate_piles(@seeds)
    else
      @seeds = @seeds.paginate(page: params[:page], per_page: PER_PAGE)
    end
    @group_by = GROUPINGS.include?(params[:group]) ? params[:group] : 'crop'
    @list_view = (params[:view] == 'list')
    @shelves = shelve(@seeds, @group_by)

    # The page and its results are the same address, so caches must tell them apart.
    response.headers['Vary'] = SEED_LIBRARY_HEADER
    return render_results if request.headers[SEED_LIBRARY_HEADER] == 'results'

    respond_with(@seeds)
  end

  def show
    @photos = @seed.photos.includes(:owner).order(created_at: :desc, id: :desc).paginate(page: params[:page], per_page: 30)
    respond_with(@seed)
  end

  def new
    @seed = Seed.new
    @seed.source = 'my own seed saving'

    if params[:planting_slug]
      @planting = Planting.find_by(slug: params[:planting_slug])
    else
      @crop = Crop.find_or_initialize_by(id: params[:crop_id])
    end
    return render json: SeedFormSerializer.new(@planting, member: current_member, crop: @crop) if request.format.json? && (@planting || @crop&.persisted?)

    respond_with(@seed)
  end

  def edit; end

  def create
    @seed = Seed.new(seed_params)
    @seed.source ||= 'my own seed saving'
    @seed.finished ||= false
    @seed.owner = current_member
    @seed.crop = @seed.parent_planting.crop if @seed.parent_planting
    saved = @seed.save
    return render_created_json if request.format.json?

    flash[:notice] = t('seeds.added_to_stash', crop: @seed.crop) if saved
    if params[:return] == 'planting'
      respond_with(@seed, location: @seed.parent_planting)
    else
      respond_with(@seed)
    end
  end

  def update
    previous_crop = @seed.crop
    if @seed.update(seed_params)
      flash[:notice] = t('seeds.updated')
      return redirect_to seed_crop_change_path(@seed, from: previous_crop.id) if ask_about_descendants?(previous_crop)
    end
    respond_with(@seed, location: seed_path(@seed, anchor: seed_section_anchor))
  end

  def destroy
    @seed.destroy
    respond_with(@seed)
  end

  private

  def ask_about_descendants?(previous_crop)
    request.format.html? && SeedCropChange.new(@seed, previous_crop).any?
  end

  # The web page, and the results the seed library fetches for it, come a page
  # of piles at a time; the data formats come a page of seeds.
  def page_of_piles?
    request.format.html? || request.headers[SEED_LIBRARY_HEADER] == 'results'
  end

  # A page of whole piles: all of one gardener's packets of a crop come on the
  # same page, never split across two. Returns that page's seeds, and the pager
  # for its links. `seeds` carries the order they should come in.
  def paginate_piles(seeds)
    piles = seeds.reorder(nil).distinct.pluck(:owner_id, :crop_id)
    crops = Crop.where(id: piles.map(&:last).uniq).includes(:parent).index_by(&:id)
    piles.sort_by! { |owner_id, crop_id| [(crops[crop_id].parent || crops[crop_id]).name.downcase, crops[crop_id].name.downcase, owner_id] }

    pager = WillPaginate::Collection.create(params[:page] || 1, PER_PAGE, piles.size) do |page|
      page.replace(piles[page.offset, page.per_page] || [])
    end
    on_page = pager.to_set
    page_seeds = seeds.where(owner_id: on_page.map(&:first), crop_id: on_page.map(&:last))
    [page_seeds.select { |seed| on_page.include?([seed.owner_id, seed.crop_id]) }, pager]
  end

  # The seed library fetches its own controls' results alone, as the scope, the
  # tabs, the results and the crop chosen, rather than the whole page.
  def render_results
    crop = { name: @search_crop.name, slug: @search_crop.slug } if @search_crop
    render json: {
      scope:   render_to_string(partial: 'seeds/scope', formats: [:html]),
      tabs:    render_to_string(partial: 'seeds/tabs', formats: [:html]),
      results: render_to_string(partial: 'seeds/results', formats: [:html]),
      crop:
    }
  end

  # The chips and scope switcher above the shelves. Everyone's seeds are the
  # ones gardeners chose to share.
  def filter(seeds)
    @everyone = @owner.blank? && @planting.blank? && page_of_piles?
    seeds = seeds.tradable if @everyone
    seeds = seeds.from_source(params[:from]) if Seed::SOURCES_BY_KIND.key?(params[:from])
    seeds = seeds.where(heirloom: params[:heirloom]) if Seed::HEIRLOOM_VALUES.include?(params[:heirloom])
    seeds = seeds.tradable if params[:shared].present?
    seeds = seeds.planted if params[:planted] == 'yes'
    seeds = seeds.not_planted if params[:planted] == 'no'
    months = sow_months
    seeds = seeds.sown_in(months) if months
    seeds = seeds.where(owner_id: gardener_ids) if @everyone && params[:gardener].present?
    seeds = seeds.where(owner_id: scoped_owner_ids) if @everyone && current_member && %w(following near).include?(params[:scope])
    seeds = seeds.where(owner_id: owner_ids_within(params[:within].to_i)) if @everyone && params[:within].to_i.positive?
    seeds
  end

  # The months asked for with "month to sow", or nil for any month.
  def sow_months
    return Seed.sow_now_months if params[:sow_month] == 'now'

    month = params[:sow_month].to_i
    [month] if (1..12).cover?(month)
  end

  # A gardener looked for by their name, whatever case it is typed in.
  def gardener_ids
    Member.where('lower(members.login_name) = ?', params[:gardener].to_s.strip.downcase).select(:id)
  end

  def scoped_owner_ids
    return current_member.followed.select(:id) if params[:scope] == 'following'

    owner_ids_within(100)
  end

  def owner_ids_within(radius)
    return [] unless current_member&.latitude

    Member.located.near([current_member.latitude, current_member.longitude], radius, units: :km).reorder(nil).pluck(:id)
  end

  # The numbers at the top of a member's library.
  def library_stats(owner)
    seeds = Seed.where(owner_id: owner.id).current.includes(:crop)
    crops = seeds.map(&:crop)
    {
      packets:   seeds.size,
      varieties: crops.uniq.size,
      crops:     crops.map { |crop| crop.parent || crop }.uniq.size,
      own:       seeds.count { |seed| seed.source == 'my own seed saving' }
    }
  end

  # The page's seeds on shelves: a hash of shelf => seeds, where the shelf is
  # the parent Crop when grouping by crop, otherwise the label to print.
  def shelve(seeds, grouping)
    shelves = seeds.group_by do |seed|
      case grouping
      when 'source' then seed.source.presence || 'other/unknown'
      when 'year' then (seed.saved_at || seed.created_at).year.to_s
      when 'use_by' then seed.plant_before&.year&.to_s || NO_USE_BY
      when 'heirloom' then seed.heirloom
      when 'gardener' then seed.owner
      else seed.crop.parent || seed.crop
      end
    end
    shelves.sort_by { |shelf, _| shelf_order(shelf, grouping) }.to_h
  end

  # Newest year saved first; soonest use-by year first, with the packets that
  # have none last; otherwise by name.
  def shelf_order(shelf, grouping)
    case grouping
    when 'year' then -shelf.to_i
    when 'use_by' then shelf == NO_USE_BY ? Float::INFINITY : shelf.to_i
    else shelf.to_s.downcase
    end
  end

  # Nearest owners first; seeds whose owner has no location go last.
  def order_by_distance(seeds, member)
    distance = Geocoder::Sql.approx_distance(member.latitude, member.longitude,
                                             'members.latitude', 'members.longitude')
    seeds.order(Arel.sql("members.latitude IS NULL, #{distance} ASC, seeds.created_at DESC"))
  end

  # Used by the React garden cards, which stay on the page and say the seeds
  # were saved (with a link to them). No flash: nothing redirects, so it would
  # turn up on whichever page is loaded next.
  def render_created_json
    if @seed.persisted?
      render json: { seed: { id: @seed.id, url: seed_path(@seed) } }, status: :created
    else
      render json: { errors: @seed.errors }, status: :unprocessable_content
    end
  end

  def seed_section_anchor
    params[:seed]&.keys == ['description'] ? 'notes' : 'facts'
  end

  def seed_params
    params.require(:seed).permit(
      :crop_id, :description, :quantity, :plant_before, :plant_before_year,
      :parent_planting_id, :saved_at,
      :days_until_maturity_min, :days_until_maturity_max,
      :variety, :batch_number, :brand, :barcode, :row_spacing, :how_to_sow, :germination_days_min, :germination_days_max,
      :organic, :gmo, :hardiness, :source,
      :heirloom, :tradable_to, :slug,
      :finished, :finished_at, sow_months: []
    )
  end

  def csv_filename
    if @owner
      "Growstuff-#{@owner.to_param}-Seeds-#{Time.zone.now.to_fs(:number)}.csv"
    else
      "Growstuff-Seeds-#{Time.zone.now.to_fs(:number)}.csv"
    end
  end
end
