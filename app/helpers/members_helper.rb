module MembersHelper
  def shorten(str, max_length)
    if str.length > max_length
      return str.slice(0, max_length - 3) + "..."
    else
      return str
    end
  end
end
