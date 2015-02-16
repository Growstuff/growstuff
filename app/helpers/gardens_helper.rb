module GardensHelper
  
  def area_abbreviations(area_verbose)
    area_abbreviations = {
      'square metre' => 'm<sup>2</sup>',
      'square foot'  => 'sqft',
      'hectare'      => 'ha',
      'acre'         => 'acre',
    }
    
    if area_abbreviations.include? area_verbose
      area_abbreviations[area_verbose].html_safe
    else 
      ""
    end
  end

end