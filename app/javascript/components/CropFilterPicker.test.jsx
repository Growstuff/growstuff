import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {beforeEach, describe, expect, it, vi} from 'vitest';

import CropFilterPicker from './CropFilterPicker';

const maize = {id: 1, name: 'maize', slug: 'maize'};

describe('CropFilterPicker', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn(async () => ({ok: true, status: 200, json: async () => [maize]})));
  });

  function setup(props = {}) {
    const {container} = render(<CropFilterPicker name="parent" label="Varieties of" {...props} />);
    return {field: container.querySelector('input[type="hidden"]'), user: userEvent.setup()};
  }

  it('starts with no crop', () => {
    expect(setup().field.value).toBe('');
  });

  it('starts with the crop it is given', () => {
    expect(setup({initial: maize}).field.value).toBe('1');
  });

  it('holds the id of the crop chosen', async () => {
    const {field, user} = setup();
    await user.type(screen.getByRole('combobox'), 'mai');
    await user.click(await screen.findByRole('option', {name: 'maize'}));
    expect(field.value).toBe('1');
  });

  it('shows the crop chosen as a chip', async () => {
    const {user} = setup();
    await user.type(screen.getByRole('combobox'), 'mai');
    await user.click(await screen.findByRole('option', {name: 'maize'}));
    expect(screen.getByRole('button', {name: 'Remove maize'})).toBeInTheDocument();
  });

  it('tells the form when a crop is removed', async () => {
    const {field, user} = setup({initial: maize});
    const changed = vi.fn();
    field.addEventListener('change', changed);
    await user.click(screen.getByRole('button', {name: 'Remove maize'}));
    expect(changed).toHaveBeenCalled();
  });
});
