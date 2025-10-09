# TODO: This assumes one autocomplete per page.
# Needs to be a function so that when we append one of these, it gets uniquely associated with the hidden controls.
jQuery ->

  if el = $( '.scientific-name-auto-suggest' )

    id = $( '.scientific-name-auto-suggest-id' )

    el.autocomplete
      minLength: 3,
      source: el.attr( 'data-source-url' ),
      focus: ( event, ui ) ->
        el.val( ui.item.canonicalName )
        id.val( ui.item.nameKey )
        false
      select: ( event, ui ) ->
        el.val( ui.item.canonicalName )
        id.val( ui.item.nameKey )
        false
      response: ( event, ui ) ->
        id.val( "" )
        for item in ui.content
          if item.name == el.val()
            id.val( item.nameKey )

    if el.data( 'uiAutocomplete' )
      el.data( 'uiAutocomplete' )._renderItem = ( ul, item ) ->
        $( '<li class="list-group-item"></li>' )
          .data( 'item.autocomplete', item )
          .append( "<a>#{item.canonicalName} (#{item.scientificName}) - #{item.rank}</a>" )
          .appendTo( ul )
