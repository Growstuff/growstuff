# frozen_string_literal: true

# What the weather and climate updaters share: a daily budget of Open-Meteo calls,
# spent at a gentle pace.
module OpenMeteoBudget
  # Open-Meteo's free tier allows 10,000 calls a day, 5,000 an hour and 600 a minute. A run, once a day, stays
  # under the hourly limit, which leaves room for retries and by-hand runs.
  DAILY_BUDGET = 4500
  # 600 calls a minute is a tenth of a second per call.
  SECONDS_PER_CALL = 0.1

  def self.included(base)
    base.attr_reader :calls_used
  end

  # progress: something that takes a line of text, such as `method(:puts)`, told what is being fetched as it goes.
  def initialize(client: OpenMeteoClient.new, today: Time.zone.today, budget: DAILY_BUDGET, seconds_per_call: SECONDS_PER_CALL,
    progress: nil)
    @client = client
    @progress = progress
    @today = today
    @budget = budget
    @seconds_per_call = seconds_per_call
    @calls_used = 0
  end

  private

  def say(line)
    @progress&.call(line)
  end
end
