import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import {localToday} from '../dates';
import SowSeedsModal from './SowSeedsModal';

vi.mock('./CropPicker', () => ({
  default: ({onChoose}) => <button type="button" onClick={() => onChoose({id: 8, name: 'Kale', slug: 'kale'})}>Pick kale</button>,
}));
vi.mock('./CropDetails', () => ({default: ({slug}) => <p>Details of {slug}</p>}));
vi.mock('./SeedPacket', () => ({default: ({packet}) => <p>Packet {packet.name}</p>}));

const nursery = {id: 1, name: 'Nursery'};
const gardens = [{id: 10, name: 'Front', slug: 'front'}, {id: 20, name: 'Back', slug: 'back'}];
const seeds = [{id: 3, crop_id: 5, crop_slug: 'tomato', name: 'Roma tomato', saved: '2024', quantity: 20, plant_before: null}];

function stubFetch(response = {ok: true, status: 201, data: {garden: {id: 1}}}) {
  const fetch = vi.fn(async () => ({ok: response.ok, status: response.status, json: async () => response.data || {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(props = {}) {
  const onSown = vi.fn();
  render(<SowSeedsModal nursery={nursery} gardens={gardens} seeds={seeds} onClose={vi.fn()} onSown={onSown} {...props} />);
  return onSown;
}

const next = () => userEvent.click(screen.getByRole('button', {name: 'Next'}));

describe('SowSeedsModal', () => {
  it('is titled Sow seeds', () => {
    setup();
    expect(screen.getByRole('dialog', {name: 'Sow seeds'})).toBeInTheDocument();
  });

  it('starts with your own packets when you have some', () => {
    setup();
    expect(screen.getByLabelText('From my seeds')).toBeChecked();
  });

  it('starts with new seeds when you have no packets', () => {
    setup({seeds: []});
    expect(screen.getByLabelText('New seeds')).toBeChecked();
  });

  it('goes on to the next step on choosing a packet', async () => {
    setup();
    await userEvent.click(screen.getByRole('button', {name: /Roma tomato/}));
    expect(screen.getByLabelText('How many seeds?')).toBeInTheDocument();
  });

  it('goes on to the next step on choosing a crop', async () => {
    setup({seeds: []});
    await userEvent.click(screen.getByRole('button', {name: 'Pick kale'}));
    expect(screen.getByText('Details of kale')).toBeInTheDocument();
  });

  it('asks about seedlings, not seeds, for seedlings', async () => {
    setup();
    await userEvent.click(screen.getByLabelText('Seedlings I got'));
    await userEvent.click(screen.getByRole('button', {name: 'Pick kale'}));
    expect(screen.getByLabelText('How many seedlings?')).toBeInTheDocument();
  });

  it('says what the packet will have left', async () => {
    setup();
    await userEvent.click(screen.getByRole('button', {name: /Roma tomato/}));
    await userEvent.clear(screen.getByLabelText('How many seeds?'));
    await userEvent.type(screen.getByLabelText('How many seeds?'), '5');
    expect(screen.getByText('That packet goes from 20 to 15.')).toBeInTheDocument();
  });

  it('cannot go on with no seeds', async () => {
    setup();
    await userEvent.click(screen.getByRole('button', {name: /Roma tomato/}));
    await userEvent.clear(screen.getByLabelText('How many seeds?'));
    expect(screen.getByRole('button', {name: 'Next'})).toBeDisabled();
  });

  it('asks which garden when sowing straight into one', async () => {
    setup();
    await userEvent.click(screen.getByRole('button', {name: /Roma tomato/}));
    await userEvent.click(screen.getByLabelText('Straight into a garden'));
    expect(screen.getByLabelText('Which garden?')).toBeInTheDocument();
  });

  it('goes back to choose other seeds', async () => {
    setup();
    await userEvent.click(screen.getByRole('button', {name: /Roma tomato/}));
    await userEvent.click(screen.getByRole('button', {name: 'Change seeds'}));
    expect(screen.getByLabelText('Search your seeds')).toBeInTheDocument();
  });

  describe('sowing into the nursery', () => {
    async function sow() {
      await userEvent.click(screen.getByRole('button', {name: /Roma tomato/}));
      await next();
      await userEvent.click(screen.getByRole('button', {name: 'Sow into the nursery'}));
    }

    it('posts the planting, using the packet', async () => {
      const fetch = stubFetch();
      setup();
      await sow();
      expect(JSON.parse(fetch.mock.calls[0][1].body)).toEqual({
        planting: {garden_id: 1, crop_id: 5, quantity: 6, planted_from: 'seed', parent_seed_id: 3, planted_at: localToday()},
        use_seeds: 1,
      });
    });

    it('hands the reply to onSown', async () => {
      stubFetch();
      const onSown = setup();
      await sow();
      expect(onSown).toHaveBeenCalledWith({garden: {id: 1}});
    });

    it('includes the notes', async () => {
      const fetch = stubFetch();
      setup();
      await userEvent.click(screen.getByRole('button', {name: /Roma tomato/}));
      await next();
      await userEvent.type(screen.getByLabelText(/Do you have any notes/), 'Soaked first');
      await userEvent.click(screen.getByRole('button', {name: 'Sow into the nursery'}));
      expect(JSON.parse(fetch.mock.calls[0][1].body).planting.description).toBe('Soaked first');
    });

    it('lists the server\'s reasons', async () => {
      stubFetch({ok: false, status: 422, data: {errors: {quantity: ['is too many']}}});
      setup();
      await sow();
      expect(await screen.findByText('Quantity is too many')).toBeInTheDocument();
    });

    it('says when the server cannot be reached', async () => {
      vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));
      setup();
      await sow();
      expect(await screen.findByText(/Couldn't reach the server/)).toBeInTheDocument();
    });
  });

  describe('sowing and adding another', () => {
    it('says what was sown', async () => {
      stubFetch();
      setup();
      await userEvent.click(screen.getByRole('button', {name: /Roma tomato/}));
      await next();
      await userEvent.click(screen.getByRole('button', {name: 'Sow and add another'}));
      expect(await screen.findByText(/Sowed 6 Roma tomato\./)).toBeInTheDocument();
    });
  });

  describe('sowing straight into a garden', () => {
    it('offers to place it on the layout', async () => {
      stubFetch();
      setup({seeds: []});
      await userEvent.click(screen.getByRole('button', {name: 'Pick kale'}));
      await userEvent.click(screen.getByLabelText('Straight into a garden'));
      await next();
      await userEvent.click(screen.getByRole('button', {name: 'Sow into Front'}));
      expect(await screen.findByRole('link', {name: 'Place on the garden layout'})).toHaveAttribute('href', '/gardens/front/layout');
    });
  });
});
