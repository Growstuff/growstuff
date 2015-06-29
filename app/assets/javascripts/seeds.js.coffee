# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('.add-datepicker').datepicker('format' : 'yyyy-mm-dd')

$ ->
  template = "<div id='template[INDEX]', class='form-group'><label class='control-label col-md-2'>Alternate name INDEX:</label><div class='col-md-8'><input class='form-control', id='alt_name[INDEX]')'></input><span class='help-block'>Alternate name of crop.</span></div></div>"

  index = 2

  $('#add-crop-row').click ->
    compiled_input = $(template.split("INDEX").join(index))
    $('#someform').append(compiled_input)
    console.log("Added %d", index)
    index = index + 1

  $('#remove-crop-row').click ->
    if (index != 0)
    	index = index - 1
    	tmp = 'template[' + index + ']'
    	element = document.getElementById(tmp)
    	element.remove()
    	console.log("Removed %s", tmp)