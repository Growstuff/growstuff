# Uses JQuery's autocomplete to suggest a crop name in lieu of a
# preposterously long select dropdown. To implement add code to
# the view like this:
#
# = text_field_tag(:crop, @resource.crop.nil? ? "" : @resource.crop.name, :class => 'crop-suggest')
# = f.hidden_field(:crop_id)

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
      response: ( event, ui ) ->
        for item in ui.content
          if item.name == el.val()
            $( "[id$='_crop_id']" ).val( item.id )
    if el.data( 'uiAutocomplete' )
      el.data( 'uiAutocomplete' )._renderItem = ( ul, item ) ->
        $( '<li></li>' )
          .data( 'item.autocomplete', item )
          .append( "<a>#{item.name}</a>" )
          .appendTo( ul )

