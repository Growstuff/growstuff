import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {beforeEach, describe, expect, it, vi} from 'vitest';

import CropPicker from './CropPicker';

const maize = {id: 1, name: 'maize', slug: 'maize'};
const mango = {id: 2, name: 'mango', slug: 'mango'};

// A fetch that answers every search with these crops.
function stubSearch(crops) {
  const fetch = vi.fn(async () => ({ok: true, status: 200, json: async () => crops}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(props = {}) {
  const onChoose = vi.fn();
  const user = userEvent.setup();
  render(<CropPicker id="crop" autoFocus={false} onChoose={onChoose} {...props} />);
  return {onChoose, user, input: screen.getByRole('combobox')};
}

describe('CropPicker', () => {
  beforeEach(() => stubSearch([maize, mango]));

  it('searches for what is typed', async () => {
    const fetch = stubSearch([maize]);
    const {user, input} = setup();
    await user.type(input, 'mai');
    await screen.findByRole('option', {name: 'maize'});
    expect(fetch).toHaveBeenLastCalledWith('/crops/search.json?term=mai', expect.anything());
  });

  it('lists the matches', async () => {
    const {user, input} = setup();
    await user.type(input, 'm');
    expect(await screen.findAllByRole('option')).toHaveLength(2);
  });

  it('does not search for a blank term', async () => {
    const fetch = stubSearch([]);
    const {user, input} = setup();
    await user.type(input, '   ');
    expect(fetch).not.toHaveBeenCalled();
  });

  it('chooses a match by clicking it', async () => {
    const {onChoose, user, input} = setup();
    await user.type(input, 'm');
    await user.click(await screen.findByRole('option', {name: 'mango'}));
    expect(onChoose).toHaveBeenCalledWith(mango);
  });

  it('chooses the top match with Enter', async () => {
    const {onChoose, user, input} = setup();
    await user.type(input, 'm');
    await screen.findAllByRole('option');
    await user.keyboard('{Enter}');
    expect(onChoose).toHaveBeenCalledWith(maize);
  });

  it('chooses the highlighted match with the arrow keys', async () => {
    const {onChoose, user, input} = setup();
    await user.type(input, 'm');
    await screen.findAllByRole('option');
    await user.keyboard('{ArrowDown}{ArrowDown}{Enter}');
    expect(onChoose).toHaveBeenCalledWith(mango);
  });

  it('closes the matches with Escape', async () => {
    const {user, input} = setup();
    await user.type(input, 'm');
    await screen.findAllByRole('option');
    await user.keyboard('{Escape}');
    expect(screen.queryByRole('option')).not.toBeInTheDocument();
  });

  it('says when nothing matches', async () => {
    stubSearch([]);
    const {user, input} = setup();
    await user.type(input, 'zzz');
    expect(await screen.findByText(/No crops match/)).toBeInTheDocument();
  });
});
