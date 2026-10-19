// Clears the finished at date field when a planting or seed is
// marked unfinished, and repopulates the field with a cached value
// when marking unfinished is undone.

jQuery(function () {
  ['planting', 'seed'].forEach(function (model) {
    let previousValue = '';

    $(`#${model}_finished`).on('click', function () {
      const finished = $(`#${model}_finished_at`);
      if (this.checked) {
        if (previousValue.length) {
          finished.val(previousValue);
        } else {
          finished.trigger('focus');
        }
      } else {
        previousValue = finished.val();
        finished.val('');
      }
    });
  });
});
