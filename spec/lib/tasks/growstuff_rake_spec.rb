# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'growstuff rake tasks' do
  before(:all) do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require 'tasks/growstuff', [Rails.root.to_s]
    Rake::Task.define_task(:environment)
  end

  describe 'growstuff:finish_expired_seeds' do
    it 'marks expired seeds as finished' do
      expired_seed = FactoryBot.create(:seed, plant_before: 1.day.ago)
      not_expired_seed = FactoryBot.create(:seed, plant_before: 1.day.from_now)
      finished_seed = FactoryBot.create(:seed, plant_before: 1.day.ago, finished: true)

      @rake['growstuff:finish_expired_seeds'].invoke

      expect(expired_seed.reload.finished).to be(true)
      expect(not_expired_seed.reload.finished).to be(false)
      expect(finished_seed.reload.finished).to be(true)
    end
  end
end
