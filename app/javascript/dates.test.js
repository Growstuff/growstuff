import {afterEach, describe, expect, it, vi} from 'vitest';

import {daysBefore, formatDate, localToday} from './dates';

describe('daysBefore', () => {
  it('goes back a number of days', () => {
    expect(daysBefore('2026-09-21', 1)).toBe('2026-09-20');
  });

  it('goes forward for a negative number', () => {
    expect(daysBefore('2026-09-21', -1)).toBe('2026-09-22');
  });

  it('crosses a month', () => {
    expect(daysBefore('2026-03-01', 1)).toBe('2026-02-28');
  });
});

describe('formatDate', () => {
  afterEach(() => vi.useRealTimers());

  it('leaves out the year in the current year', () => {
    vi.useFakeTimers({now: new Date(2026, 5, 1)});
    expect(formatDate('2026-09-12')).not.toMatch(/2026/);
  });

  it('includes the year in another year', () => {
    vi.useFakeTimers({now: new Date(2026, 5, 1)});
    expect(formatDate('2025-09-12')).toMatch(/2025/);
  });
});

describe('localToday', () => {
  it('is the browser date, padded', () => {
    vi.useFakeTimers({now: new Date(2026, 0, 5, 23, 30)});
    expect(localToday()).toBe('2026-01-05');
  });
});
