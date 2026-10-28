import { beforeEach, describe, expect, it } from 'vitest';
import { fillBlankFields, progressMessage, resultMessage } from './packet_reader';

describe('fillBlankFields', () => {
  let form;

  beforeEach(() => {
    document.body.innerHTML = `
      <form>
        <input name="seed[variety]" value="">
        <input name="seed[quantity]" value="30">
        <input name="seed[days_until_maturity_min]" value="">
        <input name="seed[days_until_maturity_max]" value="">
      </form>`;
    form = document.querySelector('form');
  });

  const found = { variety: 'Island Bay Italian', quantity: 15, daysMin: 65, daysMax: 70, rowSpacing: 50 };

  it('fills a blank field', () => {
    fillBlankFields(form, found);
    expect(form.querySelector('[name="seed[variety]"]').value).toBe('Island Bay Italian');
  });

  it('leaves a field that has something in it', () => {
    fillBlankFields(form, found);
    expect(form.querySelector('[name="seed[quantity]"]').value).toBe('30');
  });

  it('marks what it filled', () => {
    fillBlankFields(form, found);
    expect(form.querySelector('[name="seed[variety]"]').classList).toContain('packet-reader-filled');
  });

  it('names what it filled, once for the two ends of a range', () => {
    expect(fillBlankFields(form, found)).toEqual(['variety', 'days to maturity']);
  });

  it('skips what the form has no field for', () => {
    expect(fillBlankFields(form, { rowSpacing: 50 })).toEqual([]);
  });
});

describe('progressMessage', () => {
  it('says how far through reading a photo it is', () => {
    expect(progressMessage('recognizing text', 0.456, 1, 1)).toBe('Reading the photo: 46%');
  });

  it('says which photo, when there are two', () => {
    expect(progressMessage('recognizing text', 0, 2, 2)).toBe('Reading photo 2 of 2: 0%');
  });

  it('says it is loading, and that it is only slow once', () => {
    expect(progressMessage('loading language traineddata', 0.5, 1, 1)).toMatch(/only slow the first time/);
  });

  it('says nothing about steps that take no time', () => {
    expect(progressMessage('initializing api', 1, 1, 1)).toBeNull();
  });
});

describe('resultMessage', () => {
  it('says what it filled in', () => {
    expect(resultMessage({ quantity: 15 }, ['quantity'])).toMatch(/^Filled in quantity\. Check them/);
  });

  it('says why nothing changed, when it found things but the fields were full', () => {
    expect(resultMessage({ quantity: 15 }, [])).toMatch(/already have something/);
  });

  it('says it found nothing, and points to what it read', () => {
    expect(resultMessage({}, [])).toMatch(/Could not find anything.*below/);
  });
});
