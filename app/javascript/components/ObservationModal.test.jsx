import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, describe, expect, it, vi} from 'vitest';

import ObservationModal from './ObservationModal';

const planting = {id: 7, url: '/plantings/tomato-7', crop: {name: 'Tomato'}};
const kinds = [{value: 'flowering', label: 'Flowering'}, {value: 'wilting', label: 'Wilting'}, {value: 'other', label: 'Other'}];

function stubFetch(response) {
  const fetch = vi.fn(async () => ({ok: response.ok, status: response.status, json: async () => response.data || {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup() {
  const onSaved = vi.fn();
  render(<ObservationModal planting={planting} kinds={kinds} onClose={vi.fn()} onSaved={onSaved} />);
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
});
