# frozen_string_literal: true

Time::DATE_FORMATS[:default] = '%B %d, %Y at %H:%M'
Date::DATE_FORMATS[:default] = "%B %d, %Y"

Time::DATE_FORMATS[:date] = "%B %d, %Y"
Date::DATE_FORMATS[:date] = "%B %d, %Y"

Date::DATE_FORMATS[:ymd] = "%Y-%m-%d"

Time::DATE_FORMATS[:datetime] = '%B %d, %Y at %H:%M'
