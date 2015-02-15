module GardensHelper
  
  def area_abbreviations(area_verbose)
  	area_abbreviations = {
	  'square metre' => 'm<sup>2</sup>',
	  'square foot'  => 'ft<sup>2</sup>',
	  'hectare'      => 'HA',
	  'acre'         => 'A',
	}
    
    if area_abbreviations.include? area_verbose
    	area_abbreviations[area_verbose].html_safe
    else 
    	""
    end
  end

end