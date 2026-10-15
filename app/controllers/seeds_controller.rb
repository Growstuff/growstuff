# frozen_string_literal: true

class SeedsController < DataController
  GROUPINGS = %w(crop source year heirloom).freeze

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

    @seeds = @seeds.where(tradable_to: params[:tradeable_to]) if params[:tradeable_to].present?

    @query = params[:q].to_s.strip
    @seeds = @seeds.matching(@query) if @query.present?

    @in_stock_count = @seeds.current.count
    @finished_count = @seeds.finished.count
    @show_finished = (params[:finished] == '1')
    @show_all = (params[:all] == '1')
    @seeds = if @show_all then @seeds
             elsif @show_finished then @seeds.finished
             else @seeds.current
             end

    @filename = csv_filename
    @sort_by_distance = @crop.present? && current_member&.latitude.present? && current_member&.longitude.present?
    @seeds = @seeds.includes({ crop: :parent }, :owner)
    @seeds = @sort_by_distance ? order_by_distance(@seeds, current_member) : @seeds.order(created_at: :desc)
    @seeds = @seeds.paginate(page: params[:page], per_page: 30)
    @group_by = GROUPINGS.include?(params[:group]) ? params[:group] : 'crop'
    @list_view = (params[:view] == 'list')
    @open_crop_id = params[:open].presence&.to_i
    @shelves = shelve(@seeds, @group_by)

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

  # The page's seeds on shelves: a hash of shelf => seeds, where the shelf is
  # the parent Crop when grouping by crop, otherwise the label to print.
  def shelve(seeds, grouping)
    shelves = seeds.group_by do |seed|
      case grouping
      when 'source' then seed.source.presence || 'other/unknown'
      when 'year' then seed.saved_at&.year&.to_s || 'Year not recorded'
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
