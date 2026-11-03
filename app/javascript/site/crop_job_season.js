// The dialog that adds a crop's jobs asks which day the member will plant. A
// template made for part of the year says so when that day is outside it, and the
// button then says the jobs will be added anyway. The form holds the seasons, as
// the months each template is for where the member is, and the words to say.

const fillIn = (text, values) => text.replace(/%\{(\w+)\}/g, (_, key) => values[key] ?? '');

const shortDate = (value) =>
  new Date(`${value}T00:00:00`).toLocaleDateString(undefined, { day: 'numeric', month: 'short' });

// "Saturday, in 5 days", "Saturday, in 3 weeks", "Monday, tomorrow": the day of the
// week, and how far off it is, so a date picked from a calendar reads like a person said it.
export function describeDay(value, today = new Date()) {
  const date = new Date(`${value}T00:00:00`);
  const start = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const days = Math.round((date - start) / 86400000);
  const relative = new Intl.RelativeTimeFormat(undefined, { numeric: 'auto' });
  let when;
  if (Math.abs(days) < 14) when = relative.format(days, 'day');
  else if (Math.abs(days) < 60) when = relative.format(Math.round(days / 7), 'week');
  else when = relative.format(Math.round(days / 30), 'month');
  return `${date.toLocaleDateString(undefined, { weekday: 'long' })}, ${when}`;
}

function updateSeasonWarning(form) {
  const field = form.querySelector('[data-crop-job-date]');
  const warning = form.querySelector('[data-crop-job-warning]');
  const submit = form.querySelector('[data-crop-job-submit]');
  if (!field || !warning) return;

  const description = form.querySelector('[data-crop-job-when]');
  if (description) description.textContent = field.value ? describeDay(field.value) : '';

  const seasons = JSON.parse(form.dataset.cropJobSeasons || '[]');
  const month = Number(field.value.split('-')[1]);
  const outside = field.value ? seasons.filter((season) => !season.months.includes(month)) : [];

  warning.replaceChildren(
    ...outside.map((season) => {
      const line = document.createElement('p');
      line.textContent = fillIn(form.dataset.cropJobWarningText, {
        template: season.name,
        season: season.season,
        date: shortDate(field.value)
      });
      return line;
    })
  );
  warning.hidden = outside.length === 0;
  if (submit) submit.value = outside.length ? submit.dataset.anywayLabel : submit.dataset.label;
}

export function initCropJobSeason() {
  document.querySelectorAll('form[data-crop-job-seasons]').forEach((form) => {
    const field = form.querySelector('[data-crop-job-date]');
    if (!field) return;
    field.addEventListener('input', () => updateSeasonWarning(form));
    updateSeasonWarning(form);
  });
}

document.addEventListener('DOMContentLoaded', initCropJobSeason);
