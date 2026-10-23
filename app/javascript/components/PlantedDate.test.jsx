import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import {formatDate} from '../dates';
import PlantedDate from './PlantedDate';

const planting = {url: '/plantings/1', planted_at: '2020-03-05', can_edit: true};

function stubFetch(response) {
  const fetch = vi.fn(async () => ({ok: response.ok, status: response.status, json: async () => response.data || {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

async function edit(date) {
  await userEvent.click(screen.getByRole('button', {name: /Planted/}));
  const input = screen.getByLabelText('Planted date');
  await userEvent.clear(input);
  await userEvent.type(input, date);
}

describe('PlantedDate', () => {
  describe('for someone who cannot edit', () => {
    it('shows the date as text', () => {
      render(<PlantedDate planting={{...planting, can_edit: false}} onUpdated={vi.fn()} />);
      expect(screen.getByText(`Planted ${formatDate('2020-03-05')}`)).toBeInTheDocument();
    });

    it('has no button', () => {
      render(<PlantedDate planting={{...planting, can_edit: false}} onUpdated={vi.fn()} />);
      expect(screen.queryByRole('button')).not.toBeInTheDocument();
    });

    it('shows nothing without a date', () => {
      const {container} = render(<PlantedDate planting={{...planting, can_edit: false, planted_at: null}} onUpdated={vi.fn()} />);
      expect(container).toBeEmptyDOMElement();
    });
  });

  describe('for someone who can edit', () => {
    it('shows the date as a button', () => {
      render(<PlantedDate planting={planting} onUpdated={vi.fn()} />);
      expect(screen.getByRole('button', {name: `Planted ${formatDate('2020-03-05')}`})).toBeInTheDocument();
    });

    it('offers to set a missing date', () => {
      render(<PlantedDate planting={{...planting, planted_at: null}} onUpdated={vi.fn()} />);
      expect(screen.getByRole('button', {name: 'Set planted date'})).toBeInTheDocument();
    });

    it('opens a date box holding the date', async () => {
      render(<PlantedDate planting={planting} onUpdated={vi.fn()} />);
      await userEvent.click(screen.getByRole('button'));
      expect(screen.getByLabelText('Planted date')).toHaveValue('2020-03-05');
    });

    it('focuses the date box', async () => {
      render(<PlantedDate planting={planting} onUpdated={vi.fn()} />);
      await userEvent.click(screen.getByRole('button'));
      expect(screen.getByLabelText('Planted date')).toHaveFocus();
    });

    it('cancels with the cross', async () => {
      render(<PlantedDate planting={planting} onUpdated={vi.fn()} />);
      await userEvent.click(screen.getByRole('button'));
      await userEvent.click(screen.getByRole('button', {name: 'Cancel'}));
      expect(screen.queryByLabelText('Planted date')).not.toBeInTheDocument();
    });

    it('cancels with Escape', async () => {
      render(<PlantedDate planting={planting} onUpdated={vi.fn()} />);
      await userEvent.click(screen.getByRole('button'));
      await userEvent.keyboard('{Escape}');
      expect(screen.queryByLabelText('Planted date')).not.toBeInTheDocument();
    });

    it('saves the new date', async () => {
      const fetch = stubFetch({ok: true, status: 200, data: {garden: {id: 9}}});
      render(<PlantedDate planting={planting} onUpdated={vi.fn()} />);
      await edit('2020-04-01');
      await userEvent.click(screen.getByRole('button', {name: 'Save planted date'}));
      expect(fetch).toHaveBeenCalledWith('/plantings/1', expect.objectContaining({method: 'PATCH', body: JSON.stringify({planting: {planted_at: '2020-04-01'}})}));
    });

    it('saves with Enter', async () => {
      const fetch = stubFetch({ok: true, status: 200, data: {garden: {id: 9}}});
      render(<PlantedDate planting={planting} onUpdated={vi.fn()} />);
      await edit('2020-04-01');
      await userEvent.keyboard('{Enter}');
      expect(fetch).toHaveBeenCalledTimes(1);
    });

    it('hands the refreshed garden to onUpdated', async () => {
      stubFetch({ok: true, status: 200, data: {garden: {id: 9}}});
      const onUpdated = vi.fn();
      render(<PlantedDate planting={planting} onUpdated={onUpdated} />);
      await edit('2020-04-01');
      await userEvent.click(screen.getByRole('button', {name: 'Save planted date'}));
      expect(onUpdated).toHaveBeenCalledWith({id: 9});
    });

    it('does not save an unchanged date', async () => {
      const fetch = stubFetch({ok: true, status: 200});
      render(<PlantedDate planting={planting} onUpdated={vi.fn()} />);
      await userEvent.click(screen.getByRole('button'));
      await userEvent.click(screen.getByRole('button', {name: 'Save planted date'}));
      expect(fetch).not.toHaveBeenCalled();
    });

    it('shows the server\'s complaint', async () => {
      stubFetch({ok: false, status: 422, data: {errors: {planted_at: ['is in the future']}}});
      render(<PlantedDate planting={planting} onUpdated={vi.fn()} />);
      await edit('2020-04-01');
      await userEvent.click(screen.getByRole('button', {name: 'Save planted date'}));
      expect(await screen.findByRole('alert')).toHaveTextContent('Planted at is in the future');
    });

    it('says when the server cannot be reached', async () => {
      vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));
      render(<PlantedDate planting={planting} onUpdated={vi.fn()} />);
      await edit('2020-04-01');
      await userEvent.click(screen.getByRole('button', {name: 'Save planted date'}));
      expect(await screen.findByRole('alert')).toHaveTextContent('Couldn\'t reach the server');
    });
  });
});
