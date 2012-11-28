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
  # Wednesday of week 1
  iteration_start = Date.new(2012, 8, 8) + (i * 21)
  if i >= 4
    # We shifted to Thursday after iteration 3: see
    # http://lists.growstuff.org/pipermail/discuss/2012-October/000454.html
    iteration_start += 1  
    doing_start = iteration_start + 2               # Saturday of week 1
    cleanup_start = doing_start + 15                # Sunday of week 3
    cleanup_end = cleanup_start + 4                 # 2400Z Wednesday of week 3
  else
    doing_start = iteration_start + 3               # Saturday of week 1
    cleanup_start = doing_start + 15                # Sunday of week 3
    cleanup_end = cleanup_start + 3                 # 2400Z Tuesday of week 3
  end
  cal.event do
    dtstart   iteration_start
    dtend     doing_start
    summary   "Growstuff iteration #{i}: planning"
    description "Choose which stories we want to complete and who will do them"
    klass     "PUBLIC"
  end
  cal.event do
    dtstart   doing_start
    dtend     cleanup_start
    summary   "Growstuff iteration #{i}: doing"
    description "Implement stories"
    klass     "PUBLIC"
  end
  cal.event do
    dtstart   cleanup_start
    dtend     cleanup_end
    summary   "Growstuff iteration #{i}: integration and retrospective"
    description "Deploy completed stories to dev.growstuff.org and reflect on what went well and what went badly"
    klass     "PUBLIC"
  end
end

File.open("iterations.ics", 'w') { |f| f.write cal.to_ical }
