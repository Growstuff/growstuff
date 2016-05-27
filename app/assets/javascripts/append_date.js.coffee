# Displays datepicker to finished at date
# when marking a planting finished using a
# button. The button must have class 'append-date'.

jQuery ->

  el = $('.append-date')
  
  el.datepicker({'format': 'yyyy-mm-dd'})

  href = el.attr('href')

  el.click (e) ->
    e.stopPropagation()
    e.preventDefault()

    originalText = $(this).text()
    $(this).text('Confirm without date')

    $(this).bind('click.confirm', (e) ->
      link = $("<a href='#{href}' data-method='put'></a>")
      $('body').append(link)
      $(link).click()
    )

    $(this).blur (e) ->
      $(this).text(originalText)
      $(this).unbind('click.confirm')


  el.one 'changeDate', ->
    date = $(this).datepicker('getDate')
    url  = "#{href}&planting[finished_at]=#{date}"

    link = $("<a href='#{url}' data-method='put'></a>")
    $('body').append(link)
    $(link).click()
