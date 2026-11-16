import { beforeEach, describe, expect, it } from 'vitest';
import { initSeedSourceFields, updateRetailFields } from './seed_source_fields';

describe('seed source retail fields', () => {
  let form;

  beforeEach(() => {
    document.body.innerHTML = `
      <form id="seed-form">
        <select name="seed[source]">
          <option value="my own seed saving">my own seed saving</option>
          <option value="retail outlet">retail outlet</option>
          <option value="seed catalogue">seed catalogue</option>
        </select>
        <div data-retail-only style="display: none;">
          <input name="seed[brand]">
          <input name="seed[barcode]">
        </div>
      </form>`;
    form = document.getElementById('seed-form');
  });

  it('keeps retail-only fields hidden when source is not retail outlet', () => {
    const retailGroup = form.querySelector('[data-retail-only]');
    updateRetailFields(form);
    expect(retailGroup.style.display).toBe('none');
  });

  it('shows retail-only fields when source is changed to retail outlet', () => {
    const select = form.querySelector('select[name="seed[source]"]');
    const retailGroup = form.querySelector('[data-retail-only]');
    initSeedSourceFields();

    select.value = 'retail outlet';
    select.dispatchEvent(new Event('change'));

    expect(retailGroup.style.display).toBe('');
  });

  it('hides retail-only fields when source is changed back from retail outlet', () => {
    const select = form.querySelector('select[name="seed[source]"]');
    const retailGroup = form.querySelector('[data-retail-only]');
    select.value = 'retail outlet';
    initSeedSourceFields();

    expect(retailGroup.style.display).toBe('');

    select.value = 'my own seed saving';
    select.dispatchEvent(new Event('change'));

    expect(retailGroup.style.display).toBe('none');
  });
});
