import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';

describe('places map planting requests', () => {
  let getJSON;
  let nextPage;

  beforeEach(() => {
    vi.resetModules();
    document.body.innerHTML = '<div id="placesmap"></div>';
    nextPage = '/api/v1/plantings.json?page[number]=2&page[size]=100';
    getJSON = vi.fn((url, callback) => {
      callback(url.includes('/api/v1/plantings') ? {data: [], links: {next: nextPage}} : []);
    });
    vi.stubGlobal('$', {getJSON, each: (items, callback) => items.forEach(callback)});
    vi.stubGlobal('L', {
      map: () => ({setView() { return this; }, addLayer: vi.fn()}),
      tileLayer: () => ({addTo: vi.fn()}),
      MarkerClusterGroup: vi.fn(function() {}),
      icon: vi.fn(),
    });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    document.body.innerHTML = '';
  });

  it('requests 100 unfinished, non-failed plantings on the first page', async () => {
    await import('./places');
    const url = getJSON.mock.calls.find(([url]) => url.includes('/api/v1/plantings'))[0];
    expect(url).toBe('/api/v1/plantings.json?filter[finished]=false&filter[failed]=false&sort=-planted-at&page[size]=100');
  });

  describe('when more pages are available', () => {
    it('stops after two planting requests', async () => {
      await import('./places');
      expect(getJSON.mock.calls.filter(([url]) => url.includes('/api/v1/plantings'))).toHaveLength(2);
    });
  });

  describe('when there is no next page', () => {
    it('makes only one planting request', async () => {
      nextPage = null;
      await import('./places');
      expect(getJSON.mock.calls.filter(([url]) => url.includes('/api/v1/plantings'))).toHaveLength(1);
    });
  });
});
