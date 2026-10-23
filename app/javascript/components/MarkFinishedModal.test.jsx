import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import MarkFinishedModal from './MarkFinishedModal';

const planting = {id: 1, url: '/plantings/1', crop: {name: 'Tomato'}, today: '2025-06-10', planted_at: '2025-05-01'};

function stubFetch(response) {
  const fetch = vi.fn(async () => ({ok: response.ok, status: response.status, json: async () => response.data || {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(props = {}) {
  const onSaved = vi.fn();
  render(<MarkFinishedModal planting={{...planting, ...props}} onClose={vi.fn()} onSaved={onSaved} />);
  return onSaved;
}

describe('MarkFinishedModal', () => {
  it('is titled for the crop', () => {
    setup();
    expect(screen.getByRole('dialog', {name: 'Mark Tomato as finished'})).toBeInTheDocument();
  });

  it('finishes it today to start with', () => {
    setup();
    expect(screen.getByLabelText('Today')).toBeChecked();
  });

  it('saves the finish date', async () => {
    const fetch = stubFetch({ok: true, status: 200, data: {garden: {}}});
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'Mark as finished'}));
    expect(fetch).toHaveBeenCalledWith('/plantings/1', expect.objectContaining({
      method: 'PATCH',
      body: JSON.stringify({planting: {finished: true, finished_at: '2025-06-10'}}),
    }));
  });

  it('hands the refreshed garden to onSaved', async () => {
    stubFetch({ok: true, status: 200, data: {garden: {id: 4}}});
    const onSaved = setup();
    await userEvent.click(screen.getByRole('button', {name: 'Mark as finished'}));
    expect(onSaved).toHaveBeenCalledWith({id: 4});
  });

  it('starts the date box the day after it was planted', async () => {
    setup();
    await userEvent.click(screen.getByLabelText('Enter date'));
    expect(screen.getByLabelText('Date')).toHaveAttribute('min', '2025-05-02');
  });

  describe('for a planting made today', () => {
    it('does not offer today', () => {
      setup({planted_at: '2025-06-10'});
      expect(screen.queryByLabelText('Today')).not.toBeInTheDocument();
    });

    it('starts on the day after', () => {
      setup({planted_at: '2025-06-10'});
      expect(screen.getByLabelText('Date')).toHaveValue('2025-06-11');
    });
  });

  describe('when the server refuses', () => {
    it('lists the problems', async () => {
      stubFetch({ok: false, status: 422, data: {errors: {finished_at: ['is before planting']}}});
      setup();
      await userEvent.click(screen.getByRole('button', {name: 'Mark as finished'}));
      expect(await screen.findByText('Finished at is before planting')).toBeInTheDocument();
    });

    it('says when the member is not allowed', async () => {
      stubFetch({ok: false, status: 403});
      setup();
      await userEvent.click(screen.getByRole('button', {name: 'Mark as finished'}));
      expect(await screen.findByText('You can\'t change this planting.')).toBeInTheDocument();
    });
  });

  describe('when the server cannot be reached', () => {
    it('says so', async () => {
      vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));
      setup();
      await userEvent.click(screen.getByRole('button', {name: 'Mark as finished'}));
      expect(await screen.findByText(/Couldn't reach the server/)).toBeInTheDocument();
    });
  });
});
