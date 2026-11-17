import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, describe, expect, it, vi} from 'vitest';

import EditHarvestModal from './EditHarvestModal';

const planting = {id: 7, url: '/plantings/tomato-7', planted_at: '2026-01-01', crop: {name: 'Tomato'}};
const harvest = {
  slug: 'sam-tomato', plant_part_id: 2, quantity: 3, unit: 'individual', weight_quantity: null, weight_unit: null,
  harvested_at: '2026-02-10', description: 'First ones',
};
const form = {
  harvested_at: '2026-03-01',
  plant_parts: [{id: 1, name: 'leaf'}, {id: 2, name: 'fruit'}],
  units: [{label: 'individual', value: 'individual'}, {label: 'bunch', value: 'bunch'}],
  weight_units: [{label: 'kg', value: 'kg'}],
};

function stubFetch(saveResponse = {ok: true, status: 204}) {
  const fetch = vi.fn(async (url, options = {}) => (
    options.method === 'PATCH'
      ? {ok: saveResponse.ok, status: saveResponse.status, json: async () => saveResponse.data || null}
      : {ok: true, status: 200, json: async () => form}
  ));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup() {
  const onSaved = vi.fn();
  render(<EditHarvestModal planting={planting} harvest={harvest} onClose={vi.fn()} onSaved={onSaved} />);
  return onSaved;
}

describe('EditHarvestModal', () => {
  afterEach(() => vi.unstubAllGlobals());

  it('starts from what the harvest says', async () => {
    stubFetch();
    setup();
    expect(await screen.findByLabelText('Part harvested')).toHaveValue('2');
    expect(screen.getByLabelText('How many?')).toHaveValue(3);
    expect(screen.getByLabelText('Notes (optional)')).toHaveValue('First ones');
  });

  it('saves the changes to the harvest', async () => {
    const fetch = stubFetch();
    const onSaved = setup();
    await userEvent.clear(await screen.findByLabelText('How many?'));
    await userEvent.type(screen.getByLabelText('How many?'), '5');
    await userEvent.click(screen.getByRole('button', {name: 'Save changes'}));
    const [url, options] = fetch.mock.calls.find(([, call]) => call && call.method === 'PATCH');
    expect(url).toBe('/harvests/sam-tomato.json');
    expect(JSON.parse(options.body).harvest).toMatchObject({quantity: '5', plant_part_id: 2, harvested_at: '2026-02-10'});
    expect(onSaved).toHaveBeenCalled();
  });

  it('shows what the server did not like and keeps the dialog open', async () => {
    stubFetch({ok: false, status: 422, data: {errors: {harvested_at: ['cannot be harvested before planting']}}});
    const onSaved = setup();
    await userEvent.click(await screen.findByRole('button', {name: 'Save changes'}));
    expect(await screen.findByText(/cannot be harvested before planting/)).toBeInTheDocument();
    expect(onSaved).not.toHaveBeenCalled();
  });
});
