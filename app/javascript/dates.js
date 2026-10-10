// "12 Sep", or "12 Sep 2025" when it isn't this year. `iso` is a date as the
// server sends it: "2026-09-12". Parsed by hand so it isn't shifted by the
// browser's time zone.
export function formatDate(iso) {
  const [year, month, day] = iso.split('-').map(Number);
  const options = {day: 'numeric', month: 'short'};
  if (year !== new Date().getFullYear()) options.year = 'numeric';
  return new Date(year, month - 1, day).toLocaleDateString(undefined, options);
}
