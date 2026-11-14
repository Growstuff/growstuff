import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, describe, expect, it, vi} from 'vitest';

import ObservationModal from './ObservationModal';

const planting = {id: 7, url: '/plantings/tomato-7', crop: {name: 'Tomato'}};
const kinds = [
  {value: 'flowering', label: 'Flowering', icon: 'spa'},
  {value: 'wilting', label: 'Wilting', icon: 'arrow-trend-down'},
  {value: 'other', label: 'Other', icon: 'circle-question'},
];

function stubFetch(response) {
  const fetch = vi.fn(async () => ({ok: response.ok, status: response.status, json: async () => response.data || {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(props = {}) {
  const onSaved = vi.fn();
  render(<ObservationModal planting={planting} kinds={kinds} onClose={vi.fn()} onSaved={onSaved} {...props} />);
  return onSaved;
}

const body = (fetch) => JSON.parse(fetch.mock.calls[0][1].body).observation;

describe('ObservationModal', () => {
  afterEach(() => vi.unstubAllGlobals());

  it('will not save until a kind is chosen', () => {
    setup();
    expect(screen.getByRole('button', {name: 'Add observation'})).toBeDisabled();
  });

  it('saves the kind and note for today, leaving the time to the server', async () => {
    const fetch = stubFetch({ok: true, data: {garden: {id: 1}}});
    const onSaved = setup();
    await userEvent.click(screen.getByLabelText('Wilting'));
    await userEvent.type(screen.getByLabelText(/Note/), 'Droopy by noon');
    await userEvent.click(screen.getByRole('button', {name: 'Add observation'}));
    expect(fetch.mock.calls[0][0]).toBe('/plantings/tomato-7/observations.json');
    expect(body(fetch)).toEqual({kind: 'wilting', description: 'Droopy by noon'});
    expect(onSaved).toHaveBeenCalledWith({id: 1});
  });

  it('saves Other as no kind', async () => {
    const fetch = stubFetch({ok: true, data: {garden: {id: 1}}});
    setup();
    await userEvent.click(screen.getByLabelText('Other'));
    await userEvent.click(screen.getByRole('button', {name: 'Add observation'}));
    expect(body(fetch)).toMatchObject({kind: null});
  });

  it('sends the day when another is chosen', async () => {
    const fetch = stubFetch({ok: true, data: {garden: {id: 1}}});
    setup();
    await userEvent.click(screen.getByLabelText('Flowering'));
    await userEvent.click(screen.getByLabelText('Enter date'));
    await userEvent.clear(screen.getByLabelText('Date'));
    await userEvent.type(screen.getByLabelText('Date'), '2026-01-05');
    await userEvent.click(screen.getByRole('button', {name: 'Add observation'}));
    expect(body(fetch)).toMatchObject({kind: 'flowering', observed_at: '2026-01-05'});
  });

  it('will not save a day in the future', async () => {
    const fetch = stubFetch({ok: true, data: {}});
    setup();
    await userEvent.click(screen.getByLabelText('Flowering'));
    await userEvent.click(screen.getByLabelText('Enter date'));
    await userEvent.clear(screen.getByLabelText('Date'));
    await userEvent.type(screen.getByLabelText('Date'), '2999-01-01');
    expect(screen.getByRole('alert')).toHaveTextContent('not the future');
    expect(screen.getByRole('button', {name: 'Add observation'})).toBeDisabled();
    expect(fetch).not.toHaveBeenCalled();
  });

  it('leaves today to the server even when entered as a date', async () => {
    const fetch = stubFetch({ok: true, data: {garden: {id: 1}}});
    setup();
    await userEvent.click(screen.getByLabelText('Flowering'));
    await userEvent.click(screen.getByLabelText('Enter date'));
    await userEvent.click(screen.getByRole('button', {name: 'Add observation'}));
    expect(body(fetch)).not.toHaveProperty('observed_at');
  });

  it('shows what the server did not like, and keeps what was entered', async () => {
    stubFetch({ok: false, status: 422, data: {errors: {observed_at: ['can\'t be in the future']}}});
    const onSaved = setup();
    await userEvent.click(screen.getByLabelText('Flowering'));
    await userEvent.click(screen.getByRole('button', {name: 'Add observation'}));
    expect(await screen.findByText('Observed at can\'t be in the future')).toBeInTheDocument();
    expect(onSaved).not.toHaveBeenCalled();
    expect(screen.getByLabelText('Flowering')).toBeChecked();
  });

  it('shows each kind\'s icon', () => {
    setup();
    expect(screen.getByText('Wilting').closest('label').querySelector('.fa-arrow-trend-down')).not.toBeNull();
  });

  describe('editing', () => {
    const existing = {id: 3, kind: 'wilting', observed_on: '2026-01-05', description: 'Droopy'};

    it('starts from the observation', () => {
      setup({observation: existing});
      expect(screen.getByLabelText('Wilting')).toBeChecked();
      expect(screen.getByLabelText('Date')).toHaveValue('2026-01-05');
      expect(screen.getByLabelText(/Note/)).toHaveValue('Droopy');
      expect(screen.getByRole('button', {name: 'Save changes'})).toBeEnabled();
    });

    it('patches it, leaving the day alone if it was not changed', async () => {
      const fetch = stubFetch({ok: true, data: {observation: {id: 3}}});
      const onSaved = setup({observation: existing});
      await userEvent.click(screen.getByLabelText('Flowering'));
      await userEvent.click(screen.getByRole('button', {name: 'Save changes'}));
      expect(fetch.mock.calls[0][0]).toBe('/plantings/tomato-7/observations/3.json');
      expect(fetch.mock.calls[0][1].method).toBe('PATCH');
      expect(body(fetch)).toEqual({kind: 'flowering', description: 'Droopy'});
      expect(onSaved).toHaveBeenCalled();
    });

    it('saves Other as no kind', async () => {
      const fetch = stubFetch({ok: true, data: {}});
      setup({observation: {...existing, kind: null}});
      expect(screen.getByLabelText('Other')).toBeChecked();
      await userEvent.click(screen.getByRole('button', {name: 'Save changes'}));
      expect(body(fetch)).toMatchObject({kind: null});
    });

    it('moves it to now when changed to today', async () => {
      const fetch = stubFetch({ok: true, data: {}});
      setup({observation: existing});
      await userEvent.click(screen.getByLabelText('Today'));
      await userEvent.click(screen.getByRole('button', {name: 'Save changes'}));
      expect(body(fetch)).toHaveProperty('observed_at', null);
    });
  });
});
