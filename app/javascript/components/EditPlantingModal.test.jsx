import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import EditPlantingModal from './EditPlantingModal';

vi.mock('./CropPicker', () => ({
  default: ({onChoose}) => <button type="button" onClick={() => onChoose({id: 8, name: 'Kale'})}>Pick kale</button>,
}));

const planting = {id: 1, url: '/plantings/tomato', crop: {name: 'Tomato'}};
const form = {
  planting: {
    crop: {id: 5, name: 'Tomato'}, planted_at: '2025-05-01', planted_from: 'seed', sunniness: 'sun', quantity: 3,
    overall_rating: 4, description: 'Doing well', finished: false, finished_at: '', failed: false,
  },
  planted_from_values: ['seed', 'seedling'],
  sunniness_values: ['sun', 'shade'],
};

function stubFetch(...replies) {
  const fetch = vi.fn();
  replies.forEach((reply) => fetch.mockResolvedValueOnce({ok: reply.ok ?? true, status: reply.status ?? 200, json: async () => reply.data ?? {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup() {
  const onSaved = vi.fn();
  render(<EditPlantingModal planting={planting} onClose={vi.fn()} onSaved={onSaved} />);
  return onSaved;
}

describe('EditPlantingModal', () => {
  it('is titled for the crop', () => {
    stubFetch({data: form});
    setup();
    expect(screen.getByRole('dialog', {name: 'Edit Tomato'})).toBeInTheDocument();
  });

  it('shows it is loading', () => {
    stubFetch({data: form});
    setup();
    expect(screen.getByRole('status')).toHaveTextContent('Loading…');
  });

  it('loads the planting\'s edit form', async () => {
    const fetch = stubFetch({data: form});
    setup();
    await screen.findByLabelText('When?');
    expect(fetch).toHaveBeenCalledWith('/plantings/tomato/edit.json', expect.anything());
  });

  it('fills in the current values', async () => {
    stubFetch({data: form});
    setup();
    expect(await screen.findByLabelText('Tell us more about it')).toHaveValue('Doing well');
  });

  it('shows the rating', async () => {
    stubFetch({data: form});
    setup();
    expect(await screen.findByRole('radio', {name: '4 of 5'})).toBeChecked();
  });

  it('has no finished date until finished is ticked', async () => {
    stubFetch({data: form});
    setup();
    await screen.findByLabelText('When?');
    expect(screen.queryByLabelText('Finished date')).not.toBeInTheDocument();
  });

  it('asks for a finished date once finished is ticked', async () => {
    stubFetch({data: form});
    setup();
    await userEvent.click(await screen.findByLabelText('Mark as finished'));
    expect(screen.getByLabelText('Finished date')).toBeInTheDocument();
  });

  it('clears the finished date when finished is unticked', async () => {
    const fetch = stubFetch({data: {...form, planting: {...form.planting, finished: true, finished_at: '2025-06-01'}}}, {data: {garden: {}}});
    setup();
    await userEvent.click(await screen.findByLabelText('Mark as finished'));
    await userEvent.click(screen.getByRole('button', {name: 'Save'}));
    expect(JSON.parse(fetch.mock.calls[1][1].body).planting.finished_at).toBe('');
  });

  it('changes the crop', async () => {
    const fetch = stubFetch({data: form}, {data: {garden: {}}});
    setup();
    await userEvent.click(await screen.findByRole('button', {name: /Change/}));
    await userEvent.click(screen.getByRole('button', {name: 'Pick kale'}));
    await userEvent.click(screen.getByRole('button', {name: 'Save'}));
    expect(JSON.parse(fetch.mock.calls[1][1].body).planting.crop_id).toBe(8);
  });

  it('patches the planting', async () => {
    const fetch = stubFetch({data: form}, {data: {garden: {}}});
    setup();
    await userEvent.click(await screen.findByRole('button', {name: 'Save'}));
    expect(fetch).toHaveBeenLastCalledWith('/plantings/tomato', expect.objectContaining({method: 'PATCH'}));
  });

  it('hands the refreshed garden to onSaved', async () => {
    stubFetch({data: form}, {data: {garden: {id: 4}}});
    const onSaved = setup();
    await userEvent.click(await screen.findByRole('button', {name: 'Save'}));
    expect(onSaved).toHaveBeenCalledWith({id: 4});
  });

  it('lists the server\'s reasons', async () => {
    stubFetch({data: form}, {ok: false, status: 422, data: {errors: {quantity: ['must be positive']}}});
    setup();
    await userEvent.click(await screen.findByRole('button', {name: 'Save'}));
    expect(await screen.findByText('Quantity must be positive')).toBeInTheDocument();
  });

  it('says when it could not be loaded', async () => {
    stubFetch({ok: false, status: 500});
    setup();
    expect(await screen.findByRole('alert')).toHaveTextContent('Couldn’t load this planting');
  });
});
