import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {beforeEach, describe, expect, it, vi} from 'vitest';

import SeasonSuggestions from './SeasonSuggestions';
import {getJson, postJson} from '../api';

vi.mock('../api', () => ({getJson: vi.fn(), postJson: vi.fn(), csrfToken: () => 'token'}));

const season = (name, title, current = false) => ({
  name, title, current, hasData: true, months: 'Sep to Nov', mean: '14°', figures: [{label: 'Rain', value: '199 mm'}],
  url: `/suggestions/seasons/${name}`,
});
const seasons = [season('spring', 'Spring', true), season('summer', 'Summer')];
const labels = {
  average: 'average', now: 'Now', loading: 'Loading crops', loadFailed: 'Could not load', retry: 'Try again', noData: 'No weather',
  noCrops: 'Nothing', addFailed: 'Could not add', off: 'Suggestions are off', addToJobs: 'Add to planned jobs', planned: 'In your planned jobs', notForMe: 'Not for me',
};
const urls = {jobs: '/my/suggested_jobs', dismiss: '/my/dismissed_crops', planned: '/jobs'};
const crop = (id, name, extra = {}) => ({id, name, path: `/crops/${name}`, image: '/kale.png', note: 'Best at 8–12°', planned: false, ...extra});
const payload = (name, crops) => ({season: name, groups: [{key: 'optimal', heading: `Grows best in ${name}`, crops}]});

function renderIsland(props = {}) {
  return render(
    <SeasonSuggestions seasons={seasons} open="spring" enabled urls={urls} labels={labels}
      initial={{spring: payload('spring', [crop(1, 'Kale')])}} {...props} />,
  );
}

describe('SeasonSuggestions', () => {
  beforeEach(() => {
    getJson.mockReset();
    postJson.mockReset();
  });

  it('shows the crops of the season that comes with the page', () => {
    renderIsland();
    expect(screen.getByText('Kale')).toBeInTheDocument();
  });

  it('does not fetch the season that comes with the page', () => {
    renderIsland();
    expect(getJson).not.toHaveBeenCalled();
  });

  it('marks the season in progress', () => {
    renderIsland();
    expect(screen.getByText('Now')).toBeInTheDocument();
  });

  it('shows a spinner while another season loads', async () => {
    getJson.mockReturnValue(new Promise(() => {}));
    renderIsland();
    await userEvent.click(screen.getByRole('button', {name: /Summer/}));
    expect(screen.getByRole('status')).toHaveTextContent('Loading crops');
  });

  it('shows the crops once they have loaded', async () => {
    getJson.mockResolvedValue({ok: true, data: payload('summer', [crop(2, 'Tomato')])});
    renderIsland();
    await userEvent.click(screen.getByRole('button', {name: /Summer/}));
    expect(await screen.findByText('Tomato')).toBeInTheDocument();
  });

  it('asks the season for its own crops', async () => {
    getJson.mockResolvedValue({ok: true, data: payload('summer', [])});
    renderIsland();
    await userEvent.click(screen.getByRole('button', {name: /Summer/}));
    expect(getJson).toHaveBeenCalledWith('/suggestions/seasons/summer');
  });

  it('does not fetch a season again once it has loaded', async () => {
    getJson.mockResolvedValue({ok: true, data: payload('summer', [crop(2, 'Tomato')])});
    renderIsland();
    await userEvent.click(screen.getByRole('button', {name: /Summer/}));
    await screen.findByText('Tomato');
    await userEvent.click(screen.getByRole('button', {name: /Spring/}));
    await userEvent.click(screen.getByRole('button', {name: /Summer/}));
    expect(getJson).toHaveBeenCalledTimes(1);
  });

  it('closes the open season when another is opened', async () => {
    getJson.mockReturnValue(new Promise(() => {}));
    renderIsland();
    await userEvent.click(screen.getByRole('button', {name: /Summer/}));
    expect(screen.getByRole('button', {name: /Spring/})).toHaveAttribute('aria-expanded', 'false');
  });

  it('offers to try again when the crops will not load', async () => {
    getJson.mockResolvedValue({ok: false, status: 500, data: null});
    renderIsland();
    await userEvent.click(screen.getByRole('button', {name: /Summer/}));
    expect(await screen.findByRole('alert')).toHaveTextContent('Could not load');
  });

  it('loads again on retry', async () => {
    getJson.mockResolvedValueOnce({ok: false, status: 500, data: null}).mockResolvedValueOnce({ok: true, data: payload('summer', [crop(2, 'Tomato')])});
    renderIsland();
    await userEvent.click(screen.getByRole('button', {name: /Summer/}));
    await userEvent.click(await screen.findByRole('button', {name: 'Try again'}));
    await waitFor(() => expect(screen.getByText('Tomato')).toBeInTheDocument());
  });

  it('says suggestions are off, without fetching, when they are', async () => {
    renderIsland({enabled: false});
    await userEvent.click(screen.getByRole('button', {name: /Summer/}));
    expect(getJson).not.toHaveBeenCalled();
  });

  it('shows a crop already in the planned jobs as such', () => {
    renderIsland({initial: {spring: payload('spring', [crop(1, 'Kale', {planned: true})])}});
    expect(screen.getByRole('link', {name: 'In your planned jobs'})).toHaveAttribute('href', '/jobs');
  });

  it('adds a crop to planned jobs without leaving the page', async () => {
    postJson.mockResolvedValue({ok: true, status: 201, data: {added: true}});
    renderIsland();
    await userEvent.click(screen.getByRole('button', {name: 'Add to planned jobs'}));
    expect(postJson).toHaveBeenCalledWith('/my/suggested_jobs', {crop_id: 1, season: 'spring'});
  });

  it('says the crop is in the planned jobs once it is added', async () => {
    postJson.mockResolvedValue({ok: true, status: 201, data: {added: true}});
    renderIsland();
    await userEvent.click(screen.getByRole('button', {name: 'Add to planned jobs'}));
    expect(await screen.findByRole('link', {name: 'In your planned jobs'})).toBeInTheDocument();
  });

  it('puts a tick on the crop once it is added', async () => {
    postJson.mockResolvedValue({ok: true, status: 201, data: {added: true}});
    renderIsland();
    await userEvent.click(screen.getByRole('button', {name: 'Add to planned jobs'}));
    expect(await screen.findByTitle('In your planned jobs')).toBeInTheDocument();
  });

  it('has no tick on a crop that is not planned', () => {
    renderIsland();
    expect(screen.queryByTitle('In your planned jobs')).not.toBeInTheDocument();
  });

  it('marks the crop in every list of the season it is in', async () => {
    postJson.mockResolvedValue({ok: true, status: 201, data: {added: true}});
    const twice = {season: 'spring', groups: [
      {key: 'planting', heading: 'Planting', crops: [crop(1, 'Kale')]},
      {key: 'optimal', heading: 'Best', crops: [crop(1, 'Kale')]},
    ]};
    renderIsland({initial: {spring: twice}});
    await userEvent.click(screen.getAllByRole('button', {name: 'Add to planned jobs'})[0]);
    expect(await screen.findAllByTitle('In your planned jobs')).toHaveLength(2);
  });

  it('keeps the crop to add and says so when adding fails', async () => {
    postJson.mockResolvedValue({ok: false, status: 500, data: null});
    renderIsland();
    await userEvent.click(screen.getByRole('button', {name: 'Add to planned jobs'}));
    expect(await screen.findByRole('alert')).toHaveTextContent('Could not add');
  });

  it('keeps the tick when a season is closed and opened again', async () => {
    postJson.mockResolvedValue({ok: true, status: 201, data: {added: true}});
    getJson.mockReturnValue(new Promise(() => {}));
    renderIsland();
    await userEvent.click(screen.getByRole('button', {name: 'Add to planned jobs'}));
    await userEvent.click(screen.getByRole('button', {name: /Summer/}));
    await userEvent.click(screen.getByRole('button', {name: /Spring/}));
    expect(await screen.findByTitle('In your planned jobs')).toBeInTheDocument();
  });
});
