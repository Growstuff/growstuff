# Uses JQuery's autocomplete to suggest a crop name in lieu of a
# preposterously long select dropdown. To implement add code to
# the view like this:
#
# = auto_suggest @resource, :auto_suggest_source

jQuery ->
  if el = $( '.auto-suggest' )

    el.autocomplete
      minLength: 1,
      source: el.attr( "data-source-url" ),
      focus: ( event, ui ) ->
        el.val( ui.item.name )
        $( ".auto-suggest-id" ).val( ui.item.id )
        false
      select: ( event, ui ) ->
        el.val( ui.item.name )
        $( ".auto-suggest-id" ).val( ui.item.id )
        false
      response: ( event, ui ) ->
        for item in ui.content
          if item.name == el.val()
            $( ".auto-suggest-id" ).val( item.id )

    if el.data( 'uiAutocomplete' )
      el.data( 'uiAutocomplete' )._renderItem = ( ul, item ) ->
        $( '<li></li>' )
          .data( 'item.autocomplete', item )
          .append( "<a>#{item.name}</a>" )
          .appendTo( ul )

