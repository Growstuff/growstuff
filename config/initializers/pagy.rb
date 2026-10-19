# frozen_string_literal: true

# 36 a page unless a controller asks for another limit.
Pagy::OPTIONS[:limit] = 36
Pagy::OPTIONS.freeze
