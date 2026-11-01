import {describe, expect, it} from 'vitest';

import {errorMessages} from './errors';

describe('errorMessages', () => {
  it('lists a 422\'s reasons by field', () => {
    expect(errorMessages(422, {errors: {quantity: ['must be positive'], base: ['Nope']}})).toEqual(['Quantity must be positive', 'Nope']);
  });

  it('uses the forbidden message for a 403', () => {
    expect(errorMessages(403, null, {forbidden: 'Not yours'})).toEqual(['Not yours']);
  });

  it('uses the signed out message for a 401', () => {
    expect(errorMessages(401, null, {signedOut: 'Sign in'})).toEqual(['Sign in']);
  });

  it('falls back to a general message', () => {
    expect(errorMessages(500, null)).toEqual(['Something went wrong saving that. Please try again.']);
  });

  it('takes its own fallback', () => {
    expect(errorMessages(500, null, {fallback: 'Oops'})).toEqual(['Oops']);
  });
});
