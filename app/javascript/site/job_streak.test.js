import {describe, expect, it} from 'vitest';

import {flowerCount, levelFor, nextStreak, sproutCount, STREAK_WINDOW_MS, undoStreak} from './job_streak';

describe('nextStreak', () => {
  it('starts a streak with the first job', () => {
    expect(nextStreak(0, null, 1000)).toBe(1);
  });

  it('adds a job that follows closely on the last', () => {
    expect(nextStreak(2, 1000, 1000 + STREAK_WINDOW_MS)).toBe(3);
  });

  it('starts again after a gap', () => {
    expect(nextStreak(4, 1000, 1001 + STREAK_WINDOW_MS)).toBe(1);
  });
});

describe('undoStreak', () => {
  it('takes one off', () => {
    expect(undoStreak(3)).toBe(2);
  });

  it('stops at none', () => {
    expect(undoStreak(0)).toBe(0);
  });
});

describe('levelFor', () => {
  it.each([[1, 'one'], [2, 'two'], [3, 'three'], [4, 'three'], [5, 'many'], [12, 'many']])(
    'gives a streak of %i the %s message', (streak, level) => {
      expect(levelFor(streak)).toBe(level);
    },
  );
});

describe('flowerCount', () => {
  it('throws more flowers with each job in a row', () => {
    expect(flowerCount(3)).toBeGreaterThan(flowerCount(2));
  });

  it('stops at a limit', () => {
    expect(flowerCount(100)).toBe(40);
  });
});

describe('sproutCount', () => {
  it('grows nothing for the first two jobs', () => {
    expect(sproutCount(2)).toBe(0);
  });

  it('grows a flower at three in a row', () => {
    expect(sproutCount(3)).toBe(1);
  });

  it('grows one more with each job', () => {
    expect(sproutCount(6)).toBe(4);
  });

  it('stops at a limit', () => {
    expect(sproutCount(100)).toBe(12);
  });
});
