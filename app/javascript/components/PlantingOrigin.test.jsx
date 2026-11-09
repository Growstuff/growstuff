import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, describe, expect, it, vi} from 'vitest';

import PlantingOrigin from './PlantingOrigin';

const labels = {
  started_title: 'How was this %{crop} planting started?', step: 'Step %{step} of %{total}', choose: 'Choose',
  confirm_other_crop: '%{seed} is a different crop to this %{crop} planting.', link_anyway: 'Link anyway', choose_another: 'Choose another',
  change_title: 'Change where this %{crop} planting came from', change_link: 'change', change_hint: 'Crop follows', choose_different: 'Choose a different packet',
  right_now: 'Right now', linked_now: 'Linked now', not_this_packet: 'Not this', other_seeds: 'Other seeds', another_way: 'Another way started',
  other_seeds_hint: '', remove_link_hint: '', no_match: 'Nothing for %{query}', other_crops: 'Other crops', not_my_packet: 'Not mine',
  next: 'Next', step_how: 'How', step_source: 'From', label_title: 'Label', label_hint: '', search: 'Search', search_placeholder: 'Any',
  seed_list: '%{crop} seeds', seed_list_hint: 'Varieties too', seed_title: 'Is it one of your seeds?',
  some_other_seeds: 'No, other seeds', some_other_seeds_hint: '', other_ways: 'Another way', back: 'Back',
  cancel: 'Cancel', save: 'Save', skip: 'Just save "%{kind}"', unsaved: 'Did not save', remove_link: 'Remove the link',
  seed_source_title: 'Where from?', seedling_title: 'Seedling', seedling_source_title: 'Where did you get it?',
  supplier: 'Supplier', supplier_placeholder: '', label_text: 'Label text', label_text_hint: '',
};

const props = {
  url: '/plantings/tomato/origin',
  crop: 'Tomato',
  crop_id: 5,
  linked: false,
  kinds: [
    {value: 'seed', label: 'Seed', main: true, hint: '', icon_url: '/seed.svg'},
    {value: 'seedling', label: 'Seedling', main: true, hint: '', icon_url: '/sprout.svg'},
    {value: 'bulb', label: 'Bulb', main: false, hint: ''},
  ],
  seeds: [
    {id: 1, name: 'Tomato', variety: 'Brandywine', photo_url: '/packet.jpg', detail: 'Saved 2026', related: true},
    {id: 2, name: 'Basil', detail: 'Saved 2025', related: false},
  ],
  seed_sources: [{value: 'retail outlet', label: 'Shop'}],
  seedling_sources: [{value: 'nursery', label: 'Nursery'}],
  current_seed: null,
  labels,
};

function stubFetch(ok = true) {
  const fetch = vi.fn(async () => ({ok, status: ok ? 200 : 422, json: async () => ({url: '/plantings/tomato'})}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

const lastBody = (fetch) => JSON.parse(fetch.mock.calls.at(-1)[1].body);

// The "Grown from" fact's button, which is on the page outside the island.
async function openDialog(overrides = {}) {
  render(<PlantingOrigin {...props} {...overrides} />);
  document.body.insertAdjacentHTML('beforeend', '<button data-origin-dialog>change</button>');
  await userEvent.click(document.querySelector('[data-origin-dialog]'));
}

describe('PlantingOrigin', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    document.querySelectorAll('[data-origin-dialog]').forEach((element) => element.remove());
  });

  describe('when listing their packets', () => {
    async function openSeeds() {
      await openDialog();
      await userEvent.click(screen.getByRole('button', {name: /^Seed$/}));
    }

    it('shows the variety', async () => {
      await openSeeds();
      expect(screen.getByText('Brandywine')).toBeInTheDocument();
    });

    it('shows the packet photo', async () => {
      await openSeeds();
      expect(document.querySelector('img.origin-packet-photo')).toHaveAttribute('src', '/packet.jpg');
    });
  });

  describe('when linking one of their packets', () => {
    async function chooseBrandywine() {
      const fetch = stubFetch();
      await openDialog();
      await userEvent.click(screen.getByRole('button', {name: /^Seed$/}));
      await userEvent.click(screen.getByRole('button', {name: /Choose/}));
      return fetch;
    }

    it('saves it as the parent seed', async () => {
      const fetch = await chooseBrandywine();
      await waitFor(() => expect(lastBody(fetch)).toEqual({planting: {planted_from: 'seed', parent_seed_id: 1}}));
    });
  });

  describe('when the packet is of another crop', () => {
    it('asks before linking it', async () => {
      stubFetch();
      await openDialog();
      await userEvent.click(screen.getByRole('button', {name: /^Seed$/}));
      await userEvent.type(screen.getByLabelText('Search'), 'basil');
      await userEvent.click(screen.getByRole('button', {name: /Choose/}));
      expect(screen.getByText('Basil is a different crop to this Tomato planting.')).toBeInTheDocument();
    });
  });

  describe('when it is a seedling', () => {
    it('saves where it came from', async () => {
      const fetch = stubFetch();
      await openDialog();
      await userEvent.click(screen.getByRole('button', {name: /^Seedling$/}));
      await userEvent.click(screen.getByRole('button', {name: 'Nursery'}));
      await userEvent.type(screen.getByLabelText('Supplier'), 'Kings');
      await userEvent.click(screen.getByRole('button', {name: 'Save'}));
      await waitFor(() => expect(lastBody(fetch).planting.seedling_attributes).toEqual({source: 'nursery', supplier: 'Kings', label_text: ''}));
    });
  });

  describe('when it is already linked to a packet', () => {
    const linked = {current_seed: {id: 1, name: 'Brandywine tomato', detail: 'Saved 2026', related: true}};

    it('opens on the change screen showing the packet now', async () => {
      stubFetch();
      await openDialog(linked);
      expect(screen.getByText('Linked now')).toBeInTheDocument();
    });

    it('takes the link off', async () => {
      const fetch = stubFetch();
      await openDialog(linked);
      await userEvent.click(screen.getByRole('button', {name: 'Remove the link'}));
      await waitFor(() => expect(lastBody(fetch)).toEqual({planting: {parent_seed_id: null, planted_from: 'seed'}}));
    });
  });

  describe('when the seeds were not one of their packets', () => {
    it('asks about the packet as seeds are asked about when saved', async () => {
      stubFetch();
      await openDialog();
      await userEvent.click(screen.getByRole('button', {name: /^Seed$/}));
      await userEvent.click(screen.getByRole('button', {name: 'No, other seeds'}));
      await userEvent.click(screen.getByRole('button', {name: 'Shop'}));
      await userEvent.click(screen.getByRole('button', {name: 'Next'}));
      expect(await screen.findByText('Save Tomato seeds')).toBeInTheDocument();
    });
  });

  describe('when the save fails', () => {
    it('says so', async () => {
      stubFetch(false);
      await openDialog();
      await userEvent.click(screen.getByRole('button', {name: /^Bulb$/}));
      expect(await screen.findByText('Did not save')).toBeInTheDocument();
    });
  });
});
