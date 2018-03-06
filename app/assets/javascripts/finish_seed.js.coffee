# Clears the finished at date field when
# a seed is marked unfinished, and
# repopulates the field with a cached value
# marking unfinished is undone.

jQuery ->
  previousValue = ''
  $('#seed_finished').on('click', ->
    finished = $('#seed_finished_at')
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
