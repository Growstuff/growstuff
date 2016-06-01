module SeedTradesHelper

  def seed_trade_request_description(member, seed_trade)
    crop_name = seed_trade.seed.crop.name

    if member == seed_trade.seed.owner
      requester_name = seed_trade.requester.login_name
      "#{requester_name} has requested #{crop_name} seeds from you"
    else
      seed_owner_name = seed_trade.seed.owner.login_name
      "you requested #{crop_name} seeds from #{seed_owner_name}"
    end
  end
end
