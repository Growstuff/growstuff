jQuery ->
  previousValue = ''
  $('#planting_finished').on('click', ->
    finished = $('#planting_finished_at')
    if @checked
      if previousValue.length > 0
        date = previousValue 
      finished.val(date)
    else
      previousValue = finished.val()
      finished.val('')
  )