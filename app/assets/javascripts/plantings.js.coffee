# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('.add-datepicker').datepicker('format' : 'yyyy-mm-dd')

jQuery ->
  if el = $( '#crop' )
    el.autocomplete
      minLength: 1,
      source: Routes.crops_search_path(),
      focus: ( event, ui ) ->
        el.val( ui.item.name )
        $( '#planting_crop_id' ).val( ui.item.id )
        false
      select: ( event, ui ) ->
        el.val( ui.item.name )
        $( '#planting_crop_id' ).val( ui.item.id )
        false
      autoFocus: true
    .data( 'uiAutocomplete' )._renderItem = ( ul, item ) ->
      $( '<li></li>' )
        .data( 'item.autocomplete', item )
        .append( "<a>#{item.name}</a>" )
        .appendTo( ul )

