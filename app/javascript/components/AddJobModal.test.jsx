import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, describe, expect, it, vi} from 'vitest';

import {daysBefore, localToday} from '../dates';
import AddJobModal from './AddJobModal';

function stubFetch(response) {
  const fetch = vi.fn(async () => ({ok: response.ok, status: response.status, json: async () => response.data || {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(props = {}) {
  const onSaved = vi.fn();
  render(<AddJobModal onClose={vi.fn()} onSaved={onSaved} {...props} />);
  return onSaved;
}

const body = (fetch) => JSON.parse(fetch.mock.calls[0][1].body).job;

describe('AddJobModal', () => {
  afterEach(() => vi.unstubAllGlobals());

  it('saves the job for today', async () => {
    const fetch = stubFetch({ok: true, data: {}});
    setup();
    await userEvent.type(screen.getByLabelText('What needs doing?'), 'Build a trellis');
    await userEvent.click(screen.getByRole('button', {name: 'Add job'}));
    expect(body(fetch)).toMatchObject({name: 'Build a trellis', due_date: localToday()});
  });

  it('saves the job for tomorrow', async () => {
    const fetch = stubFetch({ok: true, data: {}});
    setup();
    await userEvent.type(screen.getByLabelText('What needs doing?'), 'Water');
    await userEvent.click(screen.getByLabelText('Tomorrow'));
    await userEvent.click(screen.getByRole('button', {name: 'Add job'}));
    expect(body(fetch).due_date).toBe(daysBefore(localToday(), -1));
  });

  it('hands the saved job on', async () => {
    stubFetch({ok: true, data: {id: 7}});
    const onSaved = setup();
    await userEvent.type(screen.getByLabelText('What needs doing?'), 'Water');
    await userEvent.click(screen.getByRole('button', {name: 'Add job'}));
    expect(onSaved).toHaveBeenCalledWith({id: 7});
  });

  it('shows what the server rejected', async () => {
    stubFetch({ok: false, status: 422, data: {errors: {name: ["can't be blank"]}}});
    setup();
    await userEvent.type(screen.getByLabelText('What needs doing?'), ' ');
    await userEvent.click(screen.getByRole('button', {name: 'Add job'}));
    expect(await screen.findByText("Name can't be blank")).toBeInTheDocument();
  });

  it('hides the notes until asked', () => {
    setup();
    expect(screen.queryByLabelText('Notes')).not.toBeInTheDocument();
  });

  it('saves a note', async () => {
    const fetch = stubFetch({ok: true, data: {}});
    setup();
    await userEvent.type(screen.getByLabelText('What needs doing?'), 'Water');
    await userEvent.click(screen.getByRole('button', {name: 'Add a note'}));
    await userEvent.type(screen.getByLabelText('Notes'), 'Before noon');
    await userEvent.click(screen.getByRole('button', {name: 'Add job'}));
    expect(body(fetch).description).toBe('Before noon');
  });

  it('says jobs are public', () => {
    setup();
    expect(screen.getByText('Jobs are public')).toBeInTheDocument();
  });
});
