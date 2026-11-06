import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import {daysBefore, localToday} from '../dates';
import PlantSomethingModal from './PlantSomethingModal';

vi.mock('./CropPicker', () => ({
  default: ({onChoose}) => <button type="button" onClick={() => onChoose({id: 5, name: 'Tomato'})}>Pick tomato</button>,
}));

const garden = {id: 3, name: 'Back yard'};

function stubFetch(response) {
  const fetch = vi.fn(async () => ({ok: response.ok, status: response.status, json: async () => response.data || {}}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(props = {}) {
  const onCreated = vi.fn();
  render(<PlantSomethingModal garden={garden} onClose={vi.fn()} onCreated={onCreated} {...props} />);
  return onCreated;
}

const plant = () => userEvent.click(screen.getByRole('button', {name: 'Plant it'}));

describe('PlantSomethingModal', () => {
  it('is titled for the garden', () => {
    setup();
    expect(screen.getByRole('dialog', {name: 'Plant something in Back yard'})).toBeInTheDocument();
  });

  it('starts by choosing a crop', () => {
    setup();
    expect(screen.getByRole('button', {name: 'Pick tomato'})).toBeInTheDocument();
  });

  it('has no Plant it button until a crop is chosen', () => {
    setup();
    expect(screen.queryByRole('button', {name: 'Plant it'})).not.toBeInTheDocument();
  });

  it('asks to confirm the chosen crop', async () => {
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'Pick tomato'}));
    expect(screen.getByText('Ready to plant?')).toBeInTheDocument();
  });

  it('goes back to choosing with Change', async () => {
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'Pick tomato'}));
    await userEvent.click(screen.getByRole('button', {name: /Change/}));
    expect(screen.getByRole('button', {name: 'Pick tomato'})).toBeInTheDocument();
  });

  it('starts on the confirm step when given a crop', () => {
    setup({crop: {id: 5, name: 'Kale'}});
    expect(screen.getByText('Kale')).toBeInTheDocument();
  });

  it('focuses Plant it once a crop is chosen', async () => {
    setup();
    await userEvent.click(screen.getByRole('button', {name: 'Pick tomato'}));
    expect(screen.getByRole('button', {name: 'Plant it'})).toHaveFocus();
  });

  it('leaves today to the server', async () => {
    const fetch = stubFetch({ok: true, status: 201, data: {garden: {}}});
    setup({crop: {id: 5, name: 'Tomato'}});
    await plant();
    expect(fetch).toHaveBeenCalledWith('/plantings.json', expect.objectContaining({
      body: JSON.stringify({planting: {garden_id: 3, crop_id: 5}}),
    }));
  });

  it('sends yesterday\'s date', async () => {
    const fetch = stubFetch({ok: true, status: 201, data: {garden: {}}});
    setup({crop: {id: 5, name: 'Tomato'}});
    await userEvent.click(screen.getByLabelText('Yesterday'));
    await plant();
    expect(JSON.parse(fetch.mock.calls[0][1].body).planting.planted_at).toBe(daysBefore(localToday(), 1));
  });

  it('hands the garden and crop to onCreated', async () => {
    stubFetch({ok: true, status: 201, data: {garden: {id: 3}}});
    const onCreated = setup({crop: {id: 5, name: 'Tomato'}});
    await plant();
    expect(onCreated).toHaveBeenCalledWith({id: 3}, {id: 5, name: 'Tomato'});
  });

  it('lists the server\'s reasons', async () => {
    stubFetch({ok: false, status: 422, data: {errors: {crop: ['is not allowed']}}});
    setup({crop: {id: 5, name: 'Tomato'}});
    await plant();
    expect(await screen.findByText('Crop is not allowed')).toBeInTheDocument();
  });

  it('says when it is not allowed', async () => {
    stubFetch({ok: false, status: 403});
    setup({crop: {id: 5, name: 'Tomato'}});
    await plant();
    expect(await screen.findByText('You can\'t plant in this garden.')).toBeInTheDocument();
  });

  it('says when the server cannot be reached', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));
    setup({crop: {id: 5, name: 'Tomato'}});
    await plant();
    expect(await screen.findByText(/Couldn't reach the server/)).toBeInTheDocument();
  });


  describe('with several gardens', () => {
    const gardens = [{id: 3, name: 'Back yard'}, {id: 4, name: 'Balcony'}];
    const chooseCrop = () => userEvent.click(screen.getByRole('button', {name: 'Pick tomato'}));

    it('asks which garden after the crop', async () => {
      setup({garden: undefined, gardens});
      await chooseCrop();
      expect(screen.getByRole('button', {name: 'Balcony'})).toBeInTheDocument();
    });

    it('has no Plant it button until a garden is chosen', async () => {
      setup({garden: undefined, gardens});
      await chooseCrop();
      expect(screen.queryByRole('button', {name: 'Plant it'})).not.toBeInTheDocument();
    });

    it('plants in the garden chosen', async () => {
      const fetch = stubFetch({ok: true, data: {garden: {}}});
      setup({garden: undefined, gardens});
      await chooseCrop();
      await userEvent.click(screen.getByRole('button', {name: 'Balcony'}));
      await plant();
      expect(JSON.parse(fetch.mock.calls[0][1].body).planting.garden_id).toBe(4);
    });
  });
});
