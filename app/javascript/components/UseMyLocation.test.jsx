import React from 'react';
import {act, fireEvent, render, screen} from '@testing-library/react';
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';

import UseMyLocation from './UseMyLocation';

const labels = {button: 'Locate', finding: 'Finding', failed: 'Failed', unsupported: 'No', waiting: ['one', 'two'], denied: 'Blocked', unavailable: 'Unavailable', timeout: 'Too long'};

describe('UseMyLocation', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    // A browser that never answers, so the button stays busy.
    Object.defineProperty(global.navigator, 'geolocation', {value: {getCurrentPosition: vi.fn()}, configurable: true});
  });

  afterEach(() => vi.useRealTimers());

  it.each([[1, 'Blocked'], [2, 'Unavailable'], [3, 'Too long'], [9, 'Failed']])('says why for error code %i', (code, words) => {
    navigator.geolocation.getCurrentPosition.mockImplementation((_found, fail) => fail({code}));
    render(<UseMyLocation url="/suggestions" labels={labels} />);
    fireEvent.click(screen.getByRole('button'));
    expect(screen.getByRole('alert').textContent).toBe(words);
  });

  it('shows the first waiting line once it is asked', () => {
    render(<UseMyLocation url="/suggestions" labels={labels} />);
    fireEvent.click(screen.getByRole('button'));
    expect(screen.getByRole('status').textContent).toBe('one');
  });

  it('moves on to the next waiting line', () => {
    render(<UseMyLocation url="/suggestions" labels={labels} />);
    fireEvent.click(screen.getByRole('button'));
    act(() => vi.advanceTimersByTime(2500));
    expect(screen.getByRole('status').textContent).toBe('two');
  });
});
