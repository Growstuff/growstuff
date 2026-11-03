import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {beforeEach, describe, expect, it, vi} from 'vitest';

import SeedLibrary from './SeedLibrary';

vi.mock('../islands', () => ({mountIslands: vi.fn(), unmountIslands: vi.fn()}));
vi.mock('./CropPicker', () => ({
  default: ({label, onChoose}) => <button type="button" onClick={() => onChoose({slug: 'kale'})}>{label}</button>,
}));

const labels = {
  crop: 'Crop', month_to_sow: 'Month to sow', any_month: 'Any month', gardener: 'Gardener',
  gardener_placeholder: "A gardener's name", clear_filters: 'Clear all filters', clear_crop: 'Clear crop',
  search_crop: 'Search seeds by crop', group_by: 'Group by', view: 'View', cards: 'Cards', list: 'List',
};

const props = {
  labels,
  scope: '<nav class="seed-scope"><a href="/seeds?from=retail">Everyone</a></nav>',
  tabs: '<nav><a href="/seeds?tab=mine">Mine</a></nav>',
  html: '<p>First results</p><ul class="pagination"><li><a href="/seeds?page=2">2</a></li></ul>',
  groups: [['crop', 'Crop'], ['year', 'Year']],
  filters: [
    {
      label: 'Source',
      chips: [
        {label: 'All', params: {from: null, heirloom: null}},
        {label: 'Bought', params: {from: 'bought'}},
        {label: 'Heirloom', params: {heirloom: 'heirloom'}},
      ],
    },
    {label: 'Planted', chips: [{label: 'Not planted yet', params: {planted: 'no'}}]},
    {
      label: 'Month to sow',
      wide_only: true,
      chips: [{label: 'Any month', params: {sow_month: null}}, {label: 'September', params: {sow_month: 9}}],
    },
  ],
  months: [[1, 'January'], [9, 'September']],
  sow_now: 'Sow now (November)',
  gardeners: ['Amy', 'Zed'],
  clear: {from: null, heirloom: null, sow_month: null, crop: null},
  crop: null,
  crop_search: true,
  placeholder: 'Find a crop',
};

function stubFetch(body = {scope: '<nav class="seed-scope"><a href="/seeds">Everyone</a></nav>', tabs: '<nav />', results: '<p>Next results</p>', crop: null}) {
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

  describe('filters', () => {
    it('labels the crop filter', () => {
      setup();
      expect(screen.getByText('Crop', {selector: '.seed-field-label'})).toBeInTheDocument();
    });

    it('labels the source filter', () => {
      setup();
      expect(screen.getByText('Source')).toBeInTheDocument();
    });

    it('labels the month to sow filter', () => {
      setup();
      expect(screen.getByLabelText('Month to sow')).toBeInTheDocument();
    });

    it('offers every month as a chip for a wide screen', () => {
      setup();
      expect(screen.getByRole('link', {name: 'September'})).toHaveAttribute('href', '/seeds?sow_month=9');
    });

    it('shows the month chips on wide screens only', () => {
      setup();
      expect(screen.getByRole('link', {name: 'September'}).closest('.seed-filter-row')).toHaveClass('d-none', 'd-lg-flex');
    });

    it('shows the month select on narrow screens only', () => {
      setup();
      expect(screen.getByLabelText('Month to sow').closest('.seed-filter-row')).toHaveClass('d-lg-none');
    });

    it('uses the words it is given', () => {
      setup({labels: {...labels, clear_filters: 'Alle Filter entfernen'}});
      window.history.replaceState({}, '', '/seeds?from=bought');
    });

    it('shows the scope Rails rendered', () => {
      setup();
      expect(screen.getByRole('link', {name: 'Everyone'})).toHaveAttribute('href', '/seeds?from=retail');
    });

    it('shows the new scope when the results change', async () => {
      stubFetch({scope: '<a href="/seeds?from=bought">Everyone now</a>', tabs: '<nav />', results: '<p>Next</p>', crop: null});
      setup();
      await userEvent.click(screen.getByRole('link', {name: 'Bought'}));
      expect(await screen.findByRole('link', {name: 'Everyone now'})).toBeInTheDocument();
    });

    it('keeps a gardener typed but not entered when another filter is chosen', async () => {
      const fetch = stubFetch();
      setup();
      await userEvent.type(screen.getByLabelText('Gardener'), 'Fiona');
      await userEvent.click(screen.getByRole('link', {name: 'Bought'}));
      expect(fetch).toHaveBeenLastCalledWith('/seeds?gardener=Fiona&from=bought', expect.anything());
    });

    it('labels the planted filter', () => {
      setup();
      expect(screen.getByText('Planted', {selector: '.seed-field-label'})).toBeInTheDocument();
    });

    it('adds the planted filter to the others in force', () => {
      window.history.replaceState({}, '', '/seeds?from=bought');
      setup();
      expect(screen.getByRole('link', {name: 'Not planted yet'})).toHaveAttribute('href', '/seeds?from=bought&planted=no');
    });

    it('offers sow now among the months', () => {
      setup();
      expect(screen.getByRole('option', {name: 'Sow now (November)'})).toHaveValue('now');
    });

    it('fetches the seeds sown now with the other filters kept', async () => {
      const fetch = stubFetch();
      window.history.replaceState({}, '', '/seeds?from=bought');
      setup();
      await userEvent.selectOptions(screen.getByLabelText('Month to sow'), 'Sow now (November)');
      expect(fetch).toHaveBeenCalledWith('/seeds?from=bought&sow_month=now', expect.anything());
    });

    it('suggests the gardeners given', () => {
      setup();
      expect(screen.getByLabelText('Gardener')).toHaveAttribute('list', 'seed-gardeners');
    });

    it('fetches a gardener typed and entered, keeping the other filters', async () => {
      const fetch = stubFetch();
      window.history.replaceState({}, '', '/seeds?from=bought');
      setup();
      await userEvent.type(screen.getByLabelText('Gardener'), 'Amy{Enter}');
      expect(fetch).toHaveBeenCalledWith('/seeds?from=bought&gardener=Amy', expect.anything());
    });

    it('takes the gardener off when the name is cleared', async () => {
      const fetch = stubFetch();
      window.history.replaceState({}, '', '/seeds?gardener=Amy');
      setup();
      await userEvent.clear(screen.getByLabelText('Gardener'));
      await userEvent.tab();
      expect(fetch).toHaveBeenCalledWith('/seeds', expect.anything());
    });

    it('leaves out the gardener search on a member\'s own seeds', () => {
      setup({gardeners: null});
      expect(screen.queryByLabelText('Gardener')).not.toBeInTheDocument();
    });

    it('offers every month as a chip for a wide screen', () => {
      setup();
      expect(screen.getByRole('link', {name: 'September'})).toHaveAttribute('href', '/seeds?sow_month=9');
    });

    it('shows the month chips on wide screens only', () => {
      setup();
      expect(screen.getByRole('link', {name: 'September'}).closest('.seed-filter-row')).toHaveClass('d-none', 'd-lg-flex');
    });

    it('shows the month select on narrow screens only', () => {
      setup();
      expect(screen.getByLabelText('Month to sow').closest('.seed-filter-row')).toHaveClass('d-lg-none');
    });

    it('keeps the filters in force when another is chosen', () => {
      window.history.replaceState({}, '', '/seeds?from=bought&group=year');
      setup();
      expect(screen.getByRole('link', {name: 'Heirloom'})).toHaveAttribute('href', '/seeds?from=bought&group=year&heirloom=heirloom');
    });

    it('takes a chosen chip off when it is chosen again', () => {
      window.history.replaceState({}, '', '/seeds?from=bought&heirloom=heirloom');
      setup();
      expect(screen.getByRole('link', {name: 'Heirloom'})).toHaveAttribute('href', '/seeds?from=bought');
    });

    it('takes the source off with all', () => {
      window.history.replaceState({}, '', '/seeds?from=bought&heirloom=heirloom&group=year');
      setup();
      expect(screen.getByRole('link', {name: 'All'})).toHaveAttribute('href', '/seeds?group=year');
    });

    it('keeps the filters when grouping', () => {
      window.history.replaceState({}, '', '/seeds?from=bought');
      setup();
      expect(screen.getByRole('link', {name: 'Year'})).toHaveAttribute('href', '/seeds?from=bought&group=year');
    });

    it('offers to clear all the filters when one is in force', () => {
      window.history.replaceState({}, '', '/seeds?from=bought&group=year');
      setup();
      expect(screen.getByRole('link', {name: 'Clear all filters'})).toHaveAttribute('href', '/seeds?group=year');
    });

    it('does not offer to clear when nothing is filtered', () => {
      window.history.replaceState({}, '', '/seeds?group=year');
      setup();
      expect(screen.queryByRole('link', {name: 'Clear all filters'})).not.toBeInTheDocument();
    });

    it('fetches with the month chosen and the other filters kept', async () => {
      const fetch = stubFetch();
      window.history.replaceState({}, '', '/seeds?from=bought');
      setup();
      await userEvent.selectOptions(screen.getByLabelText('Month to sow'), 'September');
      expect(fetch).toHaveBeenCalledWith('/seeds?from=bought&sow_month=9', expect.anything());
    });
  });
});
