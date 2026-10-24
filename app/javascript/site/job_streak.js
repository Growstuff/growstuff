// How jobs crossed off one after another are counted, and how much fuss each
// one gets. Kept apart from the page so it can be tested.

// Jobs crossed off within this long of the last one are in a row.
export const STREAK_WINDOW_MS = 90 * 1000;

// The streak after another job is crossed off: one more if it follows closely on
// the last, otherwise a new streak.
export function nextStreak(streak, lastAt, now) {
  if (streak > 0 && lastAt !== null && now - lastAt <= STREAK_WINDOW_MS) return streak + 1;
  return 1;
}

// The streak after a job is put back, which takes it off the count.
export function undoStreak(streak) {
  return Math.max(0, streak - 1);
}

// Which message a streak gets: the plain one, then bigger ones.
export function levelFor(streak) {
  if (streak >= 5) return 'many';
  if (streak >= 3) return 'three';
  if (streak === 2) return 'two';
  return 'one';
}

// How many flowers to throw from the tick box: a few, then more with each job in
// a row.
export function flowerCount(streak) {
  return Math.min(6 + (Math.max(streak, 1) - 1) * 5, 40);
}

// How many flowers to grow along the bottom of the page: none until three jobs
// in a row, then one more with each.
export function sproutCount(streak) {
  return streak >= 3 ? Math.min(streak - 2, 12) : 0;
}
