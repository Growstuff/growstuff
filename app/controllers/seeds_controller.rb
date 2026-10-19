# frozen_string_literal: true

class SeedsController < DataController
  GROUPINGS = %w(crop source year heirloom).freeze
  PER_PAGE = 30 # piles of packets on a page of the web page, seeds in the data formats
  SEED_LIBRARY_HEADER = 'X-Seed-Library'

  def index
    @seeds = Seed.all

    if params[:member_slug].present?
      @owner = Member.find_by!(slug: params[:member_slug])
      @seeds = @seeds.where(owner_id: @owner.id)
    end

    if params[:crop_slug].present?
      @crop = Crop.find_by(slug: params[:crop_slug])
      @seeds = @seeds.where(crop_id: @crop.id) if @crop
    end

    if params[:planting_id].present?
      @planting = Planting.find_by(slug: params[:planting_id])
      @seeds = @seeds.where(parent_planting_id: @planting.id) if @planting
    end

    @seeds = filter(@seeds)
    @filtered = %i(from within tradeable_to past).any? { |name| params[name].present? }

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
      @pagy, @seeds = paginate_piles(@seeds)
    else
      @pagy, @seeds = pagy(@seeds, limit: PER_PAGE)
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
    @pagy, @photos = pagy(@seed.photos.includes(:owner).order(created_at: :desc, id: :desc), limit: 30)
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
    return render json: SeedFormSerializer.new(@planting, member: current_member) if request.format.json? && @planting.present?

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
    return render_created_json if request.format.json? && @seed.parent_planting.present?

    flash[:notice] = t('seeds.added_to_stash', crop: @seed.crop) if saved
    if params[:return] == 'planting'
      respond_with(@seed, location: @seed.parent_planting)
    else
      respond_with(@seed)
    end
  end

  def update
    flash[:notice] = t('seeds.updated') if @seed.update(seed_params)
    respond_with(@seed)
  end

  def destroy
    @seed.destroy
    respond_with(@seed)
  end

  private

  # The web page, and the results the seed library fetches for it, come a page
  # of piles at a time; the data formats come a page of seeds.
  def page_of_piles?
    request.format.html? || request.headers[SEED_LIBRARY_HEADER] == 'results'
  end

  # A page of whole piles: all of one gardener's packets of a crop come on the
  # same page, never split across two. Returns the pager for its links, and that
  # page's seeds. `seeds` carries the order they should come in.
  def paginate_piles(seeds)
    piles = seeds.reorder(nil).distinct.pluck(:owner_id, :crop_id)
    crops = Crop.where(id: piles.map(&:last).uniq).includes(:parent).index_by(&:id)
    piles.sort_by! { |owner_id, crop_id| [(crops[crop_id].parent || crops[crop_id]).name.downcase, crops[crop_id].name.downcase, owner_id] }

    pager, page_of_piles = pagy(piles, limit: PER_PAGE)
    on_page = page_of_piles.to_set
    page_seeds = seeds.where(owner_id: on_page.map(&:first), crop_id: on_page.map(&:last))
    [pager, page_seeds.select { |seed| on_page.include?([seed.owner_id, seed.crop_id]) }]
  end

  # The seed library fetches its own controls' results alone, as the tabs, the
  # results and the crop chosen, rather than the whole page.
  def render_results
    crop = { name: @search_crop.name, slug: @search_crop.slug } if @search_crop
    render json: {
      tabs:    render_to_string(partial: 'seeds/tabs', formats: [:html]),
      results: render_to_string(partial: 'seeds/results', formats: [:html]),
      crop:
    }
  end

  # The chips and scope switcher above the shelves. Everyone's seeds are the
  # ones gardeners chose to share.
  def filter(seeds)
    @everyone = @owner.blank? && @planting.blank? && request.format.html?
    seeds = seeds.tradable if @everyone
    seeds = seeds.where(tradable_to: params[:tradeable_to]) if params[:tradeable_to].present?
    seeds = seeds.from_source(params[:from]) if Seed::SOURCES_BY_KIND.key?(params[:from])
    seeds = seeds.heirlooms if params[:from] == 'heirloom'
    seeds = seeds.tradable if params[:from] == 'shared'
    seeds = seeds.where(owner_id: scoped_owner_ids) if @everyone && current_member && %w(following near).include?(params[:scope])
    seeds = seeds.where(owner_id: owner_ids_within(params[:within].to_i)) if @everyone && params[:within].to_i.positive?
    seeds
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
      when 'heirloom' then seed.heirloom
      else seed.crop.parent || seed.crop
      end
    end
    shelves.sort_by { |shelf, _| grouping == 'year' ? -shelf.to_i : shelf.to_s.downcase }.to_h
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

  def seed_params
    params.require(:seed).permit(
      :crop_id, :description, :quantity, :plant_before, :plant_before_year,
      :parent_planting_id, :saved_at,
      :days_until_maturity_min, :days_until_maturity_max,
      :organic, :gmo, :source,
      :heirloom, :tradable_to, :slug,
      :finished, :finished_at
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
