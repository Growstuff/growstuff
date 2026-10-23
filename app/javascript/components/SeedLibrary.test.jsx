import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {beforeEach, describe, expect, it, vi} from 'vitest';

import SeedLibrary from './SeedLibrary';

vi.mock('../islands', () => ({mountIslands: vi.fn(), unmountIslands: vi.fn()}));
vi.mock('./CropPicker', () => ({
  default: ({label, onChoose}) => <button type="button" onClick={() => onChoose({slug: 'kale'})}>{label}</button>,
}));

const props = {
  tabs: '<nav><a href="/seeds?tab=mine">Mine</a></nav>',
  html: '<p>First results</p><ul class="pagination"><li><a href="/seeds?page=2">2</a></li></ul>',
  groups: [['crop', 'Crop'], ['year', 'Year']],
  chips: [{label: 'Heirloom', params: {heirloom: 'heirloom'}}],
  crop: null,
  crop_search: true,
  placeholder: 'Find a crop',
};

function stubFetch(body = {tabs: '<nav />', results: '<p>Next results</p>', crop: null}) {
  const fetch = vi.fn(async () => ({ok: true, status: 200, json: async () => body}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(overrides = {}) {
  render(<SeedLibrary {...props} {...overrides} />);
}

describe('SeedLibrary', () => {
  beforeEach(() => {
    window.history.replaceState({}, '', '/seeds');
  });

  it('shows the tabs Rails rendered', () => {
    setup();
    expect(screen.getByRole('link', {name: 'Mine'})).toBeInTheDocument();
  });

  it('shows the results Rails rendered', () => {
    setup();
    expect(screen.getByText('First results')).toBeInTheDocument();
  });

  it('offers to group', () => {
    setup();
    expect(screen.getByRole('link', {name: 'Year'})).toHaveAttribute('href', '/seeds?group=year');
  });

  it('groups by crop to start with', () => {
    setup();
    expect(screen.getByRole('link', {name: 'Crop'})).toHaveAttribute('aria-current', 'true');
  });

  it('shows cards to start with', () => {
    setup();
    expect(screen.getByRole('link', {name: 'Cards'})).toHaveAttribute('aria-current', 'true');
  });

  it('offers the list view', () => {
    setup();
    expect(screen.getByRole('link', {name: 'List'})).toHaveAttribute('href', '/seeds?view=list');
  });

  it('fetches the new results when a chip is clicked', async () => {
    const fetch = stubFetch();
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Heirloom'}));
    expect(fetch).toHaveBeenCalledWith('/seeds?heirloom=heirloom', expect.objectContaining({headers: expect.objectContaining({'X-Seed-Library': 'results'})}));
  });

  it('shows the new results without leaving the page', async () => {
    stubFetch();
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Heirloom'}));
    expect(await screen.findByText('Next results')).toBeInTheDocument();
  });

  it('changes the address', async () => {
    stubFetch();
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Heirloom'}));
    await screen.findByText('Next results');
    expect(window.location.search).toBe('?heirloom=heirloom');
  });

  it('marks the chip that is chosen', async () => {
    stubFetch();
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Heirloom'}));
    await screen.findByText('Next results');
    expect(screen.getByRole('link', {name: 'Heirloom'})).toHaveClass('active');
  });

  it('follows links in the results that stay on the page', async () => {
    const fetch = stubFetch();
    setup();
    window.HTMLElement.prototype.scrollIntoView = vi.fn();
    await userEvent.click(screen.getByRole('link', {name: '2'}));
    expect(fetch).toHaveBeenCalledWith('/seeds?page=2', expect.anything());
  });

  it('searches by the crop chosen', async () => {
    const fetch = stubFetch();
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'Search seeds by crop'}));
    expect(fetch).toHaveBeenCalledWith('/seeds?crop=kale', expect.anything());
  });

  describe('with a crop chosen', () => {
    it('shows the crop in place of the search', () => {
      setup({crop: {name: 'Kale'}});
      expect(screen.getByText('Kale')).toBeInTheDocument();
    });

    it('can clear it', async () => {
      const fetch = stubFetch();
      setup({crop: {name: 'Kale'}});
      await userEvent.click(screen.getByRole('link', {name: /Clear crop/}));
      expect(fetch).toHaveBeenCalledWith('/seeds', expect.anything());
    });
  });

  describe('without a crop search', () => {
    it('leaves out the search', () => {
      setup({crop_search: false});
      expect(screen.queryByRole('button', {name: 'Search seeds by crop'})).not.toBeInTheDocument();
    });
  });
});
