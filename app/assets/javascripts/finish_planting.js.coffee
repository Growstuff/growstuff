# Clears the finished at date field when
# a planting is marked unfinished, and
# repopulates the field with a cached value
# marking unfinished is undone.

jQuery ->
  previousValue = ''
  $('#planting_finished').on('click', ->
    finished = $('#planting_finished_at')
    if @checked
      if previousValue.length
        date = previousValue
        finished.val(date)
      else
        finished.trigger('focus')
    else
      previousValue = finished.val()
      finished.val('')
  )
