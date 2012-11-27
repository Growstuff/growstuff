#!/usr/bin/env ruby

require 'icalendar'
require 'date'

include Icalendar

if ARGV.length < 2
  puts "Usage: #{$PROGRAM_NAME} [first iteration] [final iteration]"
  exit
end

first = ARGV[0].to_i
final = ARGV[1].to_i
cal = Calendar.new

for i in first .. final do
  iteration_start = Date.new(2012, 8, 8) + (i * 21) # Wednesday of week 1
  doing_start = iteration_start + 3                 # Saturday of week 1
  cleanup_start = doing_start + 15                  # Sunday of week 3
  cleanup_end = cleanup_start + 3                   # Wednesday of week 3
  cal.event do
    dtstart   iteration_start
    dtend     doing_start
    summary   "Iteration #{i}: planning"
    description "Choose which stories we want to complete and who will do them"
    klass     "PUBLIC"
  end
  cal.event do
    dtstart   doing_start
    dtend     cleanup_start
    summary   "Iteration #{i}: doing"
    description "Implement stories"
    klass     "PUBLIC"
  end
  cal.event do
    dtstart   cleanup_start
    dtend     cleanup_end
    summary   "Iteration #{i}: integration and retrospective"
    description "Deploy completed stories to dev.growstuff.org and reflect on what went well and what went badly"
    klass      "PUBLIC"
  end
end

File.open("iterations.ics", 'w') { |f| f.write cal.to_ical }
