import { beforeEach, describe, expect, it } from 'vitest';
import { fillBlankFields, fillPacketText, progressMessage, resultMessage } from './packet_reader';

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

  it('answers a choice left at unknown', () => {
    document.body.innerHTML = '<form><select name="seed[heirloom]"><option>unknown</option><option>heirloom</option></select></form>';
    const select = document.querySelector('select');
    fillBlankFields(document.querySelector('form'), { heirloom: 'heirloom' });
    expect(select.value).toBe('heirloom');
  });

  it('leaves a choice that has been answered', () => {
    document.body.innerHTML = '<form><select name="seed[heirloom]"><option>unknown</option><option>heirloom</option><option selected>hybrid</option></select></form>';
    const select = document.querySelector('select');
    fillBlankFields(document.querySelector('form'), { heirloom: 'heirloom' });
    expect(select.value).toBe('hybrid');
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

  it('says it found nothing, and points to the text it read', () => {
    expect(resultMessage({}, [], true)).toMatch(/Could not pick out any details.*Text from the packet/);
  });

  it('says it read no text at all, when it did not', () => {
    expect(resultMessage({}, [], false)).toBe('Could not read any text on the photos of the packet.');
  });

  it('says where the text went, alongside what it filled in', () => {
    expect(resultMessage({ quantity: 15 }, ['quantity'], true)).toMatch(/Filled in quantity\..*Text from the packet/);
  });
});

describe('fillPacketText', () => {
  let form;

  beforeEach(() => {
    document.body.innerHTML = '<form><textarea name="seed[packet_text]">old</textarea></form>';
    form = document.querySelector('form');
  });

  it('puts the text in the box, replacing what was there', () => {
    fillPacketText(form, '  Sow by: December 2026  \n');
    expect(form.querySelector('textarea').value).toBe('Sow by: December 2026');
  });

  it('marks the box', () => {
    fillPacketText(form, 'text');
    expect(form.querySelector('textarea').classList).toContain('packet-reader-filled');
  });

  it('leaves the box alone when nothing was read', () => {
    fillPacketText(form, '   ');
    expect(form.querySelector('textarea').value).toBe('old');
  });

  it('says whether it saved anything', () => {
    expect(fillPacketText(form, 'text')).toBe(true);
  });

  it('has nowhere to put it when the form has no such box', () => {
    document.body.innerHTML = '<form></form>';
    expect(fillPacketText(document.querySelector('form'), 'text')).toBe(false);
  });
});
