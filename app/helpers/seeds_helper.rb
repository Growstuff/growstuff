module SeedsHelper

  def display_seed_description(seed)
  	if seed.description.nil?
  		"no description provided."
    else
    	output = truncate(seed.description, length: 130, omission: '... ')
		output += link_to('[Read more]', seed_path(seed)) if seed.description.size > 130
		output.html_safe
    end
  end
  
end