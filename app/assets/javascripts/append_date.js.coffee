# Displays datepicker to finished at date
# when marking a planting finished using a
# button. The button must have class 'append-date'.

jQuery ->

  el = $('.append-date')
  
  el.datepicker({'format': 'yyyy-mm-dd'})

  el.click (e) ->
    e.stopPropagation()
    e.preventDefault()

  el.one 'changeDate', ->
    href = $(this).attr('href')
    date = $(this).datepicker('getDate')
    url  = "#{href}&planting[finished_at]=#{date}"

    link = $("<a href='#{url}' data-method='put'></a>")
    $('body').append(link)
    $(link).click()
