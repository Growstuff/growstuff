// Clears the finished at date field when a planting or seed is
// marked unfinished, and repopulates the field with a cached value
// when marking unfinished is undone.

document.addEventListener('DOMContentLoaded', function () {
  ['planting', 'seed'].forEach(function (model) {
    const checkbox = document.getElementById(`${model}_finished`);
    if (!checkbox) return;

    let previousValue = '';

    checkbox.addEventListener('click', function () {
      const finished = document.getElementById(`${model}_finished_at`);
      if (checkbox.checked) {
        if (previousValue.length) {
          finished.value = previousValue;
        } else {
          finished.focus();
        }
      } else {
        previousValue = finished.value;
        finished.value = '';
      }
    });
  });
});
