import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import {localToday} from '../dates';
import TransplantModal from './TransplantModal';

const planting = {id: 1, slug: 'tomato-1', crop: {name: 'Tomato'}};
const gardens = [{id: 10, name: 'Front'}, {id: 20, name: 'Back'}];

function stubFetch(response) {
  const fetch = vi.fn(async () => ({ok: response.ok, status: response.status, json: async () => response.data || {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(props = {}) {
  const onDone = vi.fn();
  render(<TransplantModal planting={planting} gardens={gardens} onClose={vi.fn()} onDone={onDone} {...props} />);
  return onDone;
}

describe('TransplantModal', () => {
  it('is titled for the crop', () => {
    setup();
    expect(screen.getByRole('dialog', {name: 'Transplant Tomato'})).toBeInTheDocument();
  });

  it('chooses the first garden to start with', () => {
    setup();
    expect(screen.getByLabelText('Front')).toBeChecked();
  });

  it('transplants into the chosen garden today', async () => {
    const fetch = stubFetch({ok: true, status: 200, data: {}});
    setup();
    await userEvent.click(screen.getByLabelText('Back'));
    await userEvent.click(screen.getByRole('button', {name: 'Transplant'}));
    expect(fetch).toHaveBeenCalledWith('/plantings/tomato-1/transplant.json', expect.objectContaining({
      body: JSON.stringify({garden_id: '20', date: localToday()}),
    }));
  });

  it('hands the reply to onDone', async () => {
    stubFetch({ok: true, status: 200, data: {garden: {id: 20}}});
    const onDone = setup();
    await userEvent.click(screen.getByRole('button', {name: 'Transplant'}));
    expect(onDone).toHaveBeenCalledWith({garden: {id: 20}});
  });

  it('says when it is not allowed', async () => {
    stubFetch({ok: false, status: 403});
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'Transplant'}));
    expect(await screen.findByText('You can\'t transplant into that garden.')).toBeInTheDocument();
  });

  it('says when the server cannot be reached', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'Transplant'}));
    expect(await screen.findByText(/Couldn't reach the server/)).toBeInTheDocument();
  });

  describe('without another garden', () => {
    it('says there is nowhere to go', () => {
      setup({gardens: []});
      expect(screen.getByText(/don’t have another garden/)).toBeInTheDocument();
    });

    it('cannot transplant', () => {
      setup({gardens: []});
      expect(screen.getByRole('button', {name: 'Transplant'})).toBeDisabled();
    });
  });
});
