import {beforeEach, describe, expect, it} from 'vitest';
import {initLabelPreferences} from './label_preferences';

describe('label preferences', () => {
  let preset;
  let width;
  let height;

  beforeEach(() => {
    document.body.innerHTML = `<fieldset data-label-size-preferences>
      <select data-label-size-preset>
        <option value="">Custom</option>
        <option value="default">Default</option>
        <option value="62x29">62 × 29 mm</option>
      </select>
      <input data-label-width value="50"><input data-label-height value="30">
    </fieldset>`;
    initLabelPreferences();
    preset = document.querySelector('select');
    width = document.querySelector('[data-label-width]');
    height = document.querySelector('[data-label-height]');
  });

  it('fills both dimensions from a suggested size', () => {
    preset.value = '62x29';
    preset.dispatchEvent(new Event('change'));
    expect([width.value, height.value]).toEqual(['62', '29']);
  });

  it('clears both dimensions when removing the preference', () => {
    preset.value = 'default';
    preset.dispatchEvent(new Event('change'));
    expect([width.value, height.value]).toEqual(['', '']);
  });

  it('preserves dimensions when choosing custom', () => {
    preset.value = '';
    preset.dispatchEvent(new Event('change'));
    expect([width.value, height.value]).toEqual(['50', '30']);
  });

  it('switches to custom when a dimension is edited', () => {
    preset.value = '62x29';
    width.dispatchEvent(new Event('input'));
    expect(preset.value).toBe('');
  });
});
