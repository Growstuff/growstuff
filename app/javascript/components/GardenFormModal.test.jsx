import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import GardenFormModal from './GardenFormModal';

const form = {
  garden: {id: 1, url: '/gardens/back-yard', name: 'Back yard', description: '', location: 'Wellington', area: 12, area_unit: 'square metre', garden_type_id: 2, active: true},
  area_units: [{value: 'square metre', label: 'square metres'}, {value: 'acre', label: 'acres'}],
  garden_types: [{id: 1, name: 'Allotment'}, {id: 2, name: 'Balcony'}],
  location_help: 'Where is it?', settings_url: '/settings', member_has_location: true,
};

function stubFetch(...replies) {
  const fetch = vi.fn();
  replies.forEach((reply) => fetch.mockResolvedValueOnce({ok: reply.ok ?? true, status: reply.status ?? 200, json: async () => reply.data ?? {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(garden) {
  const onSaved = vi.fn();
  render(<GardenFormModal garden={garden} onClose={vi.fn()} onSaved={onSaved} />);
  return onSaved;
}

describe('GardenFormModal', () => {
  describe('for a new garden', () => {
    it('is titled New garden', async () => {
      stubFetch({data: form});
      setup();
      expect(screen.getByRole('dialog', {name: 'New garden'})).toBeInTheDocument();
    });

    it('loads the blank form', async () => {
      const fetch = stubFetch({data: form});
      setup();
      await screen.findByLabelText('Name');
      expect(fetch).toHaveBeenCalledWith('/gardens/new.json', expect.anything());
    });

    it('posts the garden', async () => {
      const fetch = stubFetch({data: form}, {status: 201, data: {garden: {id: 9}}});
      setup();
      await userEvent.click(await screen.findByRole('button', {name: 'Save garden'}));
      expect(fetch).toHaveBeenLastCalledWith('/gardens.json', expect.objectContaining({method: 'POST'}));
    });
  });

  describe('for an existing garden', () => {
    const garden = {id: 1, name: 'Back yard', url: '/gardens/back-yard'};

    it('is titled for the garden', () => {
      stubFetch({data: form});
      setup(garden);
      expect(screen.getByRole('dialog', {name: 'Edit Back yard'})).toBeInTheDocument();
    });

    it('shows the loading state', () => {
      stubFetch({data: form});
      setup(garden);
      expect(screen.getByRole('status')).toHaveTextContent('Loading…');
    });

    it('fills in the current values', async () => {
      stubFetch({data: form});
      setup(garden);
      expect(await screen.findByText('Wellington')).toBeInTheDocument();
    });

    it('links to where the location is changed', async () => {
      stubFetch({data: form});
      setup(garden);
      expect(await screen.findByRole('link', {name: 'Change or remove'})).toHaveAttribute('href', '/gardens/back-yard/edit');
    });

    it('offers the garden types', async () => {
      stubFetch({data: form});
      setup(garden);
      expect(await screen.findByRole('option', {name: 'Balcony'})).toBeInTheDocument();
    });

    it('patches the changes', async () => {
      const fetch = stubFetch({data: form}, {data: {garden: {id: 1}}});
      setup(garden);
      const name = await screen.findByLabelText('Name');
      await userEvent.clear(name);
      await userEvent.type(name, 'Front yard');
      await userEvent.click(screen.getByRole('button', {name: 'Save garden'}));
      expect(JSON.parse(fetch.mock.calls[1][1].body).garden.name).toBe('Front yard');
    });

    it('hands the saved garden to onSaved', async () => {
      stubFetch({data: form}, {data: {garden: {id: 1}}});
      const onSaved = setup(garden);
      await userEvent.click(await screen.findByRole('button', {name: 'Save garden'}));
      expect(onSaved).toHaveBeenCalledWith({id: 1});
    });

    it('lists the server\'s reasons', async () => {
      stubFetch({data: form}, {ok: false, status: 422, data: {errors: {name: ['is too long']}}});
      setup(garden);
      await userEvent.click(await screen.findByRole('button', {name: 'Save garden'}));
      expect(await screen.findByText('Name is too long')).toBeInTheDocument();
    });

    it('says when it could not be loaded', async () => {
      stubFetch({ok: false, status: 500});
      setup(garden);
      expect(await screen.findByRole('alert')).toHaveTextContent('Couldn’t load this garden');
    });
  });
});
