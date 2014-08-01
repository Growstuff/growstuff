jQuery ->
  if el = $( '.crop-suggest' )
    el.autocomplete
      minLength: 1,
      source: Routes.crops_search_path(),
      focus: ( event, ui ) ->
        el.val( ui.item.name )
        $( "[id$='_crop_id']" ).val( ui.item.id )
        false
      select: ( event, ui ) ->
        el.val( ui.item.name )
        $( "[id$='_crop_id']" ).val( ui.item.id )
        false
      autoFocus: true
    if el.data( 'uiAutocomplete' )
      el.data( 'uiAutocomplete' )._renderItem = ( ul, item ) ->
        $( '<li></li>' )
          .data( 'item.autocomplete', item )
          .append( "<a>#{item.name}</a>" )
          .appendTo( ul )

