# When a crop is chosen in the planting form, offer that crop's alternate names.
# Searching by an alternate name ("lauki") preselects it.
jQuery ->
  wrapper = $( '#planting-alternate-name' )
  return unless wrapper.length

  select = wrapper.find( 'select' )
  crop_id = $( '#planting_crop_id' )
  crop_input = $( '#crop' )

  load = ( id, typed ) ->
    select.empty()
    return wrapper.addClass( 'd-none' ) unless id
    $.getJSON wrapper.data( 'source-url' ), { crop_id: id }, ( names ) ->
      select.append( $( '<option>' ).text( crop_input.val() ).val( '' ) )
      for alt in names
        option = $( '<option>' ).text( alt.name ).val( alt.id )
        option.prop( 'selected', true ) if typed and alt.name.toLowerCase() == typed.toLowerCase()
        select.append( option )
      wrapper.toggleClass( 'd-none', names.length == 0 )

  crop_input.on 'autocompleteselect', ( event, ui ) ->
    typed = ui.item.matched_alternate_name
    setTimeout ->
      load( crop_id.val(), typed )
    , 0
