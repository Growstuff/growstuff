import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import SaveSeedsModal from './SaveSeedsModal';

const planting = {id: 1, url: '/plantings/tomato', crop: {name: 'Tomato'}};
const form = {parent_planting_id: 77, saved_at: '2025-06-10', tradable_to_values: ['nowhere', 'locally'], location: 'Wellington', settings_url: '/settings'};

function stubFetch(...replies) {
  const fetch = vi.fn();
  replies.forEach((reply) => fetch.mockResolvedValueOnce({ok: reply.ok ?? true, status: reply.status ?? 200, json: async () => reply.data ?? {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup() {
  const onSaved = vi.fn();
  render(<SaveSeedsModal planting={planting} onClose={vi.fn()} onSaved={onSaved} />);
  return onSaved;
}

const next = () => userEvent.click(screen.getByRole('button', {name: 'Next'}));

describe('SaveSeedsModal', () => {
  it('is titled for the crop', () => {
    stubFetch({data: form});
    setup();
    expect(screen.getByRole('dialog', {name: 'Save Tomato seeds'})).toBeInTheDocument();
  });

  it('loads the seed form for the planting', async () => {
    const fetch = stubFetch({data: form});
    setup();
    await screen.findByLabelText('About how many seeds?');
    expect(fetch).toHaveBeenCalledWith('/plantings/tomato/seeds/new.json', expect.anything());
  });

  it('fills the amount from a quick choice', async () => {
    stubFetch({data: form});
    setup();
    await userEvent.click(await screen.findByRole('button', {name: 'About 100'}));
    expect(screen.getByLabelText('About how many seeds?')).toHaveValue(100);
  });

  it('summarises an unknown amount', async () => {
    stubFetch({data: form});
    setup();
    await screen.findByLabelText('About how many seeds?');
    await next();
    expect(screen.getByText('Not sure')).toBeInTheDocument();
  });

  it('keeps them out of trade to start with', async () => {
    stubFetch({data: form});
    setup();
    await screen.findByLabelText('About how many seeds?');
    await next();
    expect(screen.getByLabelText('Not for trade')).toBeChecked();
  });

  it('says where they are offered from', async () => {
    stubFetch({data: form});
    setup();
    await screen.findByLabelText('About how many seeds?');
    await next();
    await userEvent.click(screen.getByLabelText('Locally'));
    expect(screen.getByText('Offered from Wellington.')).toBeInTheDocument();
  });

  it('asks for a location when there is none', async () => {
    stubFetch({data: {...form, location: null}});
    setup();
    await screen.findByLabelText('About how many seeds?');
    await next();
    await userEvent.click(screen.getByLabelText('Locally'));
    expect(screen.getByRole('link', {name: 'Set your location'})).toHaveAttribute('href', '/settings');
  });

  it('posts the seeds', async () => {
    const fetch = stubFetch({data: form}, {status: 201, data: {seed: {url: '/seeds/1'}}});
    setup();
    await userEvent.type(await screen.findByLabelText('About how many seeds?'), '50');
    await next();
    await next();
    await userEvent.click(screen.getByRole('button', {name: 'Save seeds'}));
    expect(JSON.parse(fetch.mock.calls[1][1].body).seed).toMatchObject({parent_planting_id: 77, saved_at: '2025-06-10', quantity: '50', tradable_to: 'nowhere'});
  });

  it('hands the new seed to onSaved', async () => {
    stubFetch({data: form}, {status: 201, data: {seed: {url: '/seeds/1'}}});
    const onSaved = setup();
    await screen.findByLabelText('About how many seeds?');
    await next();
    await next();
    await userEvent.click(screen.getByRole('button', {name: 'Save seeds'}));
    expect(onSaved).toHaveBeenCalledWith({url: '/seeds/1'});
  });

  it('lists the server\'s reasons', async () => {
    stubFetch({data: form}, {ok: false, status: 422, data: {errors: {quantity: ['is negative']}}});
    setup();
    await screen.findByLabelText('About how many seeds?');
    await next();
    await next();
    await userEvent.click(screen.getByRole('button', {name: 'Save seeds'}));
    expect(await screen.findByText('Quantity is negative')).toBeInTheDocument();
  });

  it('says when the form could not be loaded', async () => {
    stubFetch({ok: false, status: 500});
    setup();
    expect(await screen.findByRole('alert')).toHaveTextContent('Couldn’t load the seed form');
  });
});
