module GardensHelper

  def display_garden_description(garden)
  	if garden.description.nil?
  		"no description provided."
    else
    	output = truncate(garden.description, length: 130, omission: '... ')
    	output += link_to('[Read more]', garden_path(garden)) if garden.description.size > 130
    	output.html_safe
    end
  end

  def display_garden_plantings(garden)
  	if garden.plantings.empty?
      None
    else
    	output = ""
    	garden.plantings.current.each do |p|
    		output = p.quantity.nil? ? "0 " : "#{p.quantity} "
    		output += link_to p.crop.name, p
    		output = output.html_safe
            if p.planted_at
            	output += ", planted on #{p.planted_at}"
            end
        end

        output = truncate(output, length: 100, omission: '... ')
        output += link_to('[View more plantings]', garden_path(garden)) if output.size > 100
        output.html_safe
    end
  end
end