# frozen_string_literal: true

class CounterCaches < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :gardens_count, :integer
    add_column :members, :harvests_count, :integer
    add_column :members, :seeds_count, :integer

    Member.unscoped.find_each do |member|
      Member.reset_counters(member.id, :gardens)
      Member.reset_counters(member.id, :harvests)
      Member.reset_counters(member.id, :seeds)
      Member.reset_counters(member.id, :plantings)
      say "Member #{member.login_name} counter caches updated"
    end
  end
end
