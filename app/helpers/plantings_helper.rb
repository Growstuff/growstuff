module PlantingsHelper
  def display (notification)
    if notification.post
      # comment on the post in question
      new_comment_url(:post_id => notification.post.id)
    else
      # by default, reply link sends a PM in return
      reply_notification_url(notification)
    end
  end

  def display_days_before_maturity(planting)
    if planting.finished?
      0
    elsif !planting.finished_at.nil?
      if ((p = planting.finished_at - DateTime.now).to_i) <= 0
        0
      else
      	p.to_i
      end
    elsif planting.days_before_maturity.nil?
      "unknown"
    else
      if ((p = (planting.planted_at + planting.days_before_maturity) - DateTime.now).to_i) <= 0
        0
      else
      	p.to_i
      end
    end
  end

  def display_finished(planting)
    if !planting.finished_at.nil?
      planting.finished_at
    elsif planting.finished
      "Yes (no date specified)"
    else
      "(no date specified)"
    end
  end
  
  def display_sunniness(planting)
    if !planting.sunniness.blank?
      planting.sunniness
    else
      "n/a"
    end
  end

  def display_planted_from(planting)
    if !planting.planted_from.blank?
      planting.planted_from
    else
      "n/a"
    end
  end
end