// "12 Sep", or "12 Sep 2025" when it isn't this year. `iso` is a date as the
// server sends it: "2026-09-12". Parsed by hand so it isn't shifted by the
// browser's time zone.
export function formatDate(iso) {
  const [year, month, day] = iso.split('-').map(Number);
  const options = {day: 'numeric', month: 'short'};
  if (year !== new Date().getFullYear()) options.year = 'numeric';
  return new Date(year, month - 1, day).toLocaleDateString(undefined, options);
}

// "2026-09-21" a number of days earlier (or later, if negative), as
// "2026-09-20". Worked out in UTC so the browser's time zone can't shift it.
export function daysBefore(iso, days) {
  const [year, month, day] = iso.split('-').map(Number);
  return new Date(Date.UTC(year, month - 1, day - days)).toISOString().slice(0, 10);
}

// Today in the browser's own time zone, as "2026-09-21".
export function localToday() {
  const now = new Date();
  const pad = (number) => String(number).padStart(2, '0');
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
}

// The next Saturday after "2026-10-17", as "2026-10-24": a day to plan a sowing
// for. Today is never the answer, so a Saturday gives the one after it.
export function nextSaturday(iso) {
  const [year, month, day] = iso.split('-').map(Number);
  const weekday = new Date(Date.UTC(year, month - 1, day)).getUTCDay();
  return daysBefore(iso, -(((6 - weekday + 7) % 7) || 7));
}

// "Sat 24 Oct", for a date as the server sends it.
export function dayLabel(iso) {
  const [year, month, day] = iso.split('-').map(Number);
  return new Date(year, month - 1, day).toLocaleDateString(undefined, {weekday: 'short', day: 'numeric', month: 'short'});
}
