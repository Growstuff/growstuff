import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import RecordHarvestModal from './RecordHarvestModal';

const planting = {id: 1, url: '/plantings/tomato', crop: {name: 'Tomato'}, planted_at: '2025-05-01'};
const form = {
  planting_id: 77, harvested_at: '2025-06-10', plant_part_id: 1,
  plant_parts: [{id: 1, name: 'fruit'}, {id: 2, name: 'leaf'}],
  units: [{value: 'individual', label: 'individual'}, {value: 'bunch', label: 'bunches'}],
  weight_units: [{value: 'kg', label: 'kg'}, {value: 'lb', label: 'lb'}],
};

function stubFetch(...replies) {
  const fetch = vi.fn();
  replies.forEach((reply) => fetch.mockResolvedValueOnce({ok: reply.ok ?? true, status: reply.status ?? 200, json: async () => reply.data ?? {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(props = {}) {
  const onSaved = vi.fn();
  render(<RecordHarvestModal planting={{...planting, ...props}} onClose={vi.fn()} onSaved={onSaved} />);
  return onSaved;
}

const next = () => userEvent.click(screen.getByRole('button', {name: 'Next'}));

async function toNotes() {
  await userEvent.click(await screen.findByRole('option', {name: /^fruit/}));
  await userEvent.type(screen.getByLabelText('How many?'), '3');
  await next();
  await next();
}

describe('RecordHarvestModal', () => {
  it('is titled for the crop', () => {
    stubFetch({data: form});
    setup();
    expect(screen.getByRole('dialog', {name: 'Record a harvest of Tomato'})).toBeInTheDocument();
  });

  it('loads the harvest form for the planting', async () => {
    const fetch = stubFetch({data: form});
    setup();
    await screen.findByRole('combobox');
    expect(fetch).toHaveBeenCalledWith('/plantings/tomato/harvests/new.json', expect.anything());
  });

  it('starts by asking for the part', async () => {
    stubFetch({data: form});
    setup();
    expect(await screen.findByRole('combobox', {name: 'What part did you harvest?'})).toBeInTheDocument();
  });

  it('then asks how much', async () => {
    stubFetch({data: form});
    setup();
    await userEvent.click(await screen.findByRole('option', {name: /^fruit/}));
    expect(screen.getByLabelText('How many?')).toBeInTheDocument();
  });

  it('then asks when', async () => {
    stubFetch({data: form});
    setup();
    await userEvent.click(await screen.findByRole('option', {name: /^fruit/}));
    await next();
    expect(screen.getByRole('group', {name: 'When did you harvest it?'})).toBeInTheDocument();
  });

  it('summarises the amount on later steps', async () => {
    stubFetch({data: form});
    setup();
    await userEvent.click(await screen.findByRole('option', {name: /^fruit/}));
    await userEvent.type(screen.getByLabelText('How many?'), '3');
    await next();
    expect(screen.getByText('3 individual')).toBeInTheDocument();
  });

  it('goes back a step', async () => {
    stubFetch({data: form});
    setup();
    await userEvent.click(await screen.findByRole('option', {name: /^fruit/}));
    await next();
    await userEvent.click(screen.getByRole('button', {name: 'Back'}));
    expect(screen.getByLabelText('How many?')).toBeInTheDocument();
  });

  it('does not offer yesterday for a planting made yesterday', async () => {
    stubFetch({data: form});
    setup({planted_at: '2025-06-09'});
    await userEvent.click(await screen.findByRole('option', {name: /^fruit/}));
    await next();
    expect(screen.queryByLabelText('Yesterday')).not.toBeInTheDocument();
  });

  it('posts the harvest', async () => {
    const fetch = stubFetch({data: form}, {status: 201, data: {garden: {id: 4}}});
    setup();
    await toNotes();
    await userEvent.click(screen.getByRole('button', {name: 'Save harvest'}));
    expect(JSON.parse(fetch.mock.calls[1][1].body).harvest).toMatchObject({planting_id: 77, plant_part_id: 1, harvested_at: '2025-06-10', quantity: '3', unit: 'individual'});
  });

  it('hands the refreshed garden to onSaved', async () => {
    stubFetch({data: form}, {status: 201, data: {garden: {id: 4}}});
    const onSaved = setup();
    await toNotes();
    await userEvent.click(screen.getByRole('button', {name: 'Save harvest'}));
    expect(onSaved).toHaveBeenCalledWith({id: 4});
  });

  it('lists the server\'s reasons', async () => {
    stubFetch({data: form}, {ok: false, status: 422, data: {errors: {quantity: ['is too big']}}});
    setup();
    await toNotes();
    await userEvent.click(screen.getByRole('button', {name: 'Save harvest'}));
    expect(await screen.findByText('Quantity is too big')).toBeInTheDocument();
  });

  it('says when the server cannot be reached', async () => {
    const fetch = stubFetch({data: form});
    setup();
    await toNotes();
    fetch.mockRejectedValueOnce(new Error('offline'));
    await userEvent.click(screen.getByRole('button', {name: 'Save harvest'}));
    expect(await screen.findByText(/Couldn't reach the server/)).toBeInTheDocument();
  });

  it('says when the form could not be loaded', async () => {
    stubFetch({ok: false, status: 500});
    setup();
    expect(await screen.findByRole('alert')).toHaveTextContent('Couldn’t load the harvest form');
  });
});
