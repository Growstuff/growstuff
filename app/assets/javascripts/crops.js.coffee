jQuery ->
  $('#add-sci_name-row').css("display", "inline-block")
  $('#remove-sci_name-row').css("display", "inline-block")
  $("#add-alt_name-row").css("display", "inline-block")
  $("#remove-alt_name-row").css("display", "inline-block")

-$ ->
  sci_template = "<div id='sci_template[INDEX]' class='template col-md-12'><div class='col-md-2'><label>Scientific name INDEX:</label></div><div class='col-md-8'><input name='sci_name[INDEX]' class='form-control', id='sci_name[INDEX]')'></input><span class='help-block'>Scientific name of crop.</span></div><div class='col-md-2'></div></div>"

  sci_index = $('#scientific_names .template').length + 1

  $('#add-sci_name-row').click ->
    compiled_input = $(sci_template.split("INDEX").join(sci_index))
    $('#scientific_names').append(compiled_input)
    sci_index = sci_index + 1

  $('#remove-sci_name-row').click ->
    if (sci_index > 2)
      sci_index = sci_index - 1
      tmp = 'sci_template[' + sci_index + ']'
      element = document.getElementById(tmp)
      element.remove()

  alt_template = "<div id='alt_template[INDEX]' class='template col-md-12'><div class='col-md-2'><label>Alternate name INDEX:</label></div><div class='col-md-8'><input name='alt_name[INDEX]' class='form-control', id='alt_name[INDEX]')'></input><span class='help-block'>Alternate name of crop.</span></div><div class='col-md-2'></div></div>"

  alt_index = $('#alternate_names .template').length + 1

  $('#add-alt_name-row').click ->
    compiled_input = $(alt_template.split("INDEX").join(alt_index))
    $('#alternate_names').append(compiled_input)
    alt_index = alt_index + 1

  $('#remove-alt_name-row').click ->
    if (alt_index > 2)
      alt_index = alt_index - 1
      tmp = 'alt_template[' + alt_index + ']'
      element = document.getElementById(tmp)
      console.log("%s",tmp)
      element.remove()