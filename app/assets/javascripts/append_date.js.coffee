jQuery ->
  
  $('.append-date').datepicker({'format': 'yyyy-mm-dd'})

  $('.append-date').click (e) ->
    e.stopPropagation()
    e.preventDefault()

  $('.append-date').one 'changeDate', ->
    href = $(this).attr('href')
    date = $(this).datepicker('getDate')
    url  = "#{href}&planting[finished_at]=#{date}"

    link = $("<a href='#{url}' data-method='put'></a>")
    $('body').append(link)
    $(link).click()
