# frozen_string_literal: true

# Narrows the list of crops on crops#index to what the params ask for. Only the parent crop can be filtered by without signing in;
# the rest go by the member's location, plantings or follows. It holds the working out and no text.
#   suits    crops whose temperatures suit the member's location in some season
#   season   seasons (spring, summer, autumn, winter), for crops that suit it when sown in any of those named; all if none
#   nearby   crops gardeners near the member have planted
#   seeds    crops the member has seeds of
#   friends  crops the people the member follows have planted
#   history  'before' for crops the member has planted, 'never' for those they haven't; both or neither leaves every crop
#   parent   the id of a crop, for its varieties
class CropFilter
  HISTORIES = %w(before never).freeze
  SEASONS = %w(spring summer autumn winter).freeze

  def initialize(member, params)
    @member = member
    @params = params
  end

  def apply(crops)
    crops = crops.where(parent_id: parent.id) if parent
    crops = crops.where(id: suiting_ids) if suiting?
    crops = crops.where(id: dashboard.crop_ids_planted_nearby) if nearby?
    crops = crops.where(id: dashboard.crop_ids_with_seeds) if seeds?
    crops = crops.where(id: dashboard.crop_ids_planted_by_followed) if friends?
    crops = crops.where(id: dashboard.crop_ids_planted) if history == 'before'
    crops = crops.where.not(id: dashboard.crop_ids_planted) if history == 'never'
    crops
  end

  def active?
    [parent, suiting?, nearby?, friends?, seeds?, history].any?
  end

  def suits?
    flag?(:suits)
  end

  %i(nearby seeds friends).each do |name|
    define_method(:"#{name}?") { @member.present? && flag?(name) }
  end

  # The seasons asked for, in their order.
  def seasons
    asked = Array(@params[:season]).map(&:to_s)
    SEASONS.select { |each| asked.include?(each) }
  end

  # 'before' or 'never' when just one of them is asked for, since asking for both is asking for every crop.
  def history
    asked = Array(@params[:history]).map(&:to_s) & HISTORIES
    asked.first if @member && asked.one?
  end

  def parent
    return @parent if defined?(@parent)

    @parent = (Crop.approved.find_by(id: @params[:parent]) if @params[:parent].present?)
  end

  # Whether the member's location can say what suits it: it is set, and we hold weather for it.
  def climate?
    climate.present?
  end

  def suiting?
    @member.present? && (suits? || seasons.any?)
  end

  private

  def flag?(name)
    ActiveModel::Type::Boolean.new.cast(@params[name]) == true
  end

  def dashboard
    @dashboard ||= MemberDashboard.new(@member)
  end

  def climate
    return @climate if defined?(@climate)

    @climate = (SeasonalClimate.for(@member) if @member)
  end

  # The ids of the crops that suit the location, none when we can't tell what does.
  def suiting_ids
    return [] unless climate

    months = seasons.any? ? climate.seasons.select { |each| seasons.include?(each.name.to_s) }.flat_map(&:months).uniq : (1..12).to_a
    SeasonalCrops.new(climate).sown_in(months, limit: nil).values.flatten.map(&:id)
  end
end
