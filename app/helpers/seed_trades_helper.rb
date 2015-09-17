module SeedTradesHelper

  def link_to_show_trade(member, seed_trade)
    if member == seed_trade.seed.owner
      requester_name = seed_trade.requester.login_name
      crop_name      = seed_trade.seed.crop.name
      "#{requester_name} requested #{crop_name} seeds from you"
    else
      crop_name   = seed_trade.seed.crop.name
      seed_owner_name = seed_trade.seed.owner.login_name
      "you requested #{crop_name} seeds to #{seed_owner_name}"
    end
  end
end
