module PlantingsHelper
  def display_finished(planting)
    if planting.finished_at.present?
      planting.finished_at
    elsif planting.finished
      "Yes (no date specified)"
    else
      "(no date specified)"
    end
  end

  def display_planted_from(planting)
    planting.planted_from.presence || "not specified"
  end

  def display_planting_quantity(planting)
    planting.quantity.presence || "not specified"
  end

  def display_planting(planting)
    if planting.quantity.to_i > 0 && planting.planted_from.present?
      "#{planting.owner} planted #{pluralize(planting.quantity, planting.planted_from)}."
    elsif planting.quantity.to_i > 0
      "#{planting.owner} planted #{pluralize(planting.quantity, 'unit')}."
    elsif planting.planted_from.present?
      "#{planting.owner} planted #{planting.planted_from.pluralize}."
    else
      "#{planting.owner}."
    end
  end

  def plantings_active_tickbox_path(owner, show_all)
    show_inactive_tickbox_path('plantings', owner, show_all)
  end

  def days_from_now_to_finished(planting)
    return unless planting.finish_is_predicatable?

    (planting.finish_predicted_at - Time.zone.today).to_i
  end

  def days_from_now_to_first_harvest(planting)
    return unless planting.planted_at.present? && planting.first_harvest_predicted_at.present?

    (planting.first_harvest_predicted_at - Time.zone.today).to_i
  end

  def days_from_now_to_last_harvest(planting)
    return unless planting.planted_at.present? && planting.last_harvest_predicted_at.present?

    (planting.last_harvest_predicted_at - Time.zone.today).to_i
  end

  def planting_classes(planting)
    classes = []
    classes << 'planting-growing' if planting.growing?
    classes << 'planting-finished' if planting.finished?
    classes << 'planting-harvest-time' if planting.harvest_time?
    classes << 'planting-late' if planting.late?
    classes << 'planting-super-late' if planting.super_late?
    classes.join(' ')
  end

  def planting_status(planting)
    if planting.crop.perennial
      t 'planting.status.perennial'
    elsif planting.finished?
      t 'planting.status.finished'
    elsif !planting.finish_is_predicatable?
      t 'planting.status.not_enough_data'
    elsif planting.harvest_time?
      t 'planting.status.harvesting'
    elsif planting.late?
      t 'planting.status.late'
    elsif planting.growing?
      t 'planting.status.growing'
    elsif !planting.planted?
      t 'planting.status.not planted'
    else
      t 'planting.status.unknown'
    end
  end

  def planting_events(planting)
    @events = []

    add_event(Time.now.to_date, 'today')
    add_event(planting.planted_at, 'planted') if planting.planted_at
    planting.harvests.each.each do |harvest|
      add_event(harvest.harvested_at, render('harvests/tiny', harvest: harvest))
    end
    planting.child_seeds.each do |seed|
      add_event(seed.created_at.to_date, 'seeds collected')
    end

    # planting.photos.each do |photo|
    #   add_event(photo.date_taken.to_date, render('photos/tiny', photo: photo))
    # end
    if planting.first_harvest_predicted_at.present?
      add_event(planting.first_harvest_predicted_at, "first harvest expected")
    end
    add_event(planting.last_harvest_predicted_at, 'last harvest expected') if planting.last_harvest_predicted_at.present?
    add_event(planting.finished_at, 'finished') if planting.finished_at.present?
    add_event(planting.finish_predicted_at, 'finish expected') if planting.finish_predicted_at.present?


    @events = @events.sort_by { |hsh| hsh[:date] }
    return @events
  end

  def add_event(date, content)
    @events << { date: date, content: content }
  end
end
