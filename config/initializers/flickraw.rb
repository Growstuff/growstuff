# frozen_string_literal: true

# Flickr now sends lists of plain strings, such as owner.gift.eligible_durations in a
# photo's info, and FlickRaw 0.9.10 fails on them ("undefined method 'keys' for
# String"). Leave anything that is not a hash as it came.
module FlickRawPlainValues
  def build(value, type)
    value.is_a?(Hash) || value.is_a?(FlickRaw::Response) ? super : value
  end
end

FlickRaw::Response.singleton_class.prepend(FlickRawPlainValues)
