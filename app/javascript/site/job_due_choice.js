// The days offered when adding a job: Change date shows a calendar, and the day
// picked there is what the job is saved with.

const customRadio = function (picker) {
  return picker.closest('.job-due-custom').querySelector('input[type="radio"]');
};

document.addEventListener('change', function (event) {
  const target = event.target;
  if (!target.closest) return;

  const picker = target.closest('.job-due-picker');
  if (picker) {
    const radio = customRadio(picker);
    radio.value = picker.value;
    radio.checked = true;
    return;
  }

  const list = target.closest('.job-due-list');
  if (!list || target.type !== 'radio') return;

  const custom = list.querySelector('.job-due-custom');
  const chosen = custom.contains(target);
  const calendar = custom.querySelector('.job-due-picker');
  calendar.hidden = !chosen;
  if (chosen) calendar.focus();
});
