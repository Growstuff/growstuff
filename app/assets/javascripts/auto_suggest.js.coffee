# Uses JQuery's autocomplete to make a suggestion in lieu of a
# preposterously long select dropdown. To implement add code to
# the view like this:
#
# = auto_suggest @resource, :auto_suggest_source
#
# You must also add a search method to the resource's controller.

jQuery ->
  if el = $( '.auto-suggest' )

    id = $( '.auto-suggest-id' )
    submit = $( '[name="commit"]' )
    errorContainer = $( '<span></span>' ).insertAfter(el)

    el.autocomplete
      minLength: 1,
      source: el.attr( 'data-source-url' ),
      autoFocus: true,
      focus: ( event, ui ) ->
        el.val( ui.item.name )
        id.val( ui.item.id )
        false
      select: ( event, ui ) ->
        el.val( ui.item.name )
        id.val( ui.item.id )
        false
      response: ( event, ui ) ->
        id.val( "" )
        for item in ui.content
          if item.name == el.val()
            id.val( item.id )

    if el.data( 'uiAutocomplete' )
      el.data( 'uiAutocomplete' )._renderItem = ( ul, item ) ->
        $( '<li></li>' )
          .data( 'item.autocomplete', item )
          .append( "<a>#{item.name}</a>" )
          .appendTo( ul )

    submit.on( 'click', (e) ->
      if el.val() != '' && id.val() == ''
        e.preventDefault()
        errorContainer.prepend( '<p><em>That\'s not in our database.</em></p>' )
        el.css( 'background-color', '#ffe6e6' )
        $( 'html, body' ).animate({
          scrollTop: ( el.offset().top ) - 200
        }, 200)
    )

    el.focus( ->
      el.css( 'background-color', '#fff' )
      errorContainer.find( 'p' ).remove()
    )
