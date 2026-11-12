import { describe, it, expect, beforeEach, vi } from 'vitest';
import { filterUrl, swapIn, setUp } from './crop_filters';

const page = (names) => `<div id="crop-results">${names}</div><div class="crop-filter-status"></div>`;

describe('filterUrl', () => {
  let form;

  beforeEach(() => {
    document.body.innerHTML = `<form class="crop-filters" action="/crops">
      <select name="parent"><option value="" selected></option></select>
      <input type="checkbox" name="season[]" value="spring" checked>
      <input type="checkbox" name="season[]" value="winter" checked>
      <input type="checkbox" name="nearby" value="1">
    </form>`;
    form = document.querySelector('form');
  });

  it('leaves out empty fields and unticked boxes', () => {
    expect(decodeURIComponent(filterUrl(form))).toBe('/crops?season[]=spring&season[]=winter');
  });

  it('is the bare address with nothing chosen', () => {
    document.querySelectorAll('input').forEach((input) => { input.checked = false; });
    expect(filterUrl(form)).toBe('/crops');
  });
});

describe('swapIn', () => {
  it('replaces the list with the new one', () => {
    document.body.innerHTML = page('kale');
    swapIn(page('tomato'));
    expect(document.querySelector('#crop-results').textContent).toBe('tomato');
  });
});

describe('setUp', () => {
  let fetcher;

  beforeEach(() => {
    document.body.innerHTML = `<form class="crop-filters" action="/crops"><div class="crop-filters-apply"></div>
      <input type="checkbox" name="nearby" value="1"></form>${page('kale')}`;
    fetcher = vi.fn(() => Promise.resolve({ ok: true, text: () => Promise.resolve(page('tomato')) }));
    setUp(document.querySelector('form'), fetcher);
  });

  it('hides the button', () => {
    expect(document.querySelector('.crop-filters-apply').hidden).toBe(true);
  });

  it('fetches the list when a filter changes', async () => {
    const box = document.querySelector('input');
    box.checked = true;
    box.dispatchEvent(new Event('change', { bubbles: true }));
    await vi.waitFor(() => expect(document.querySelector('#crop-results').textContent).toBe('tomato'));
    expect(fetcher.mock.calls[0][0]).toBe('/crops?nearby=1');
  });
});
