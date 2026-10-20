import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {useState} from 'react';
import {describe, expect, it, vi} from 'vitest';

import GbifNameInput from './GbifNameInput';

const maize = {key: 1, canonicalName: 'Zea mays', scientificName: 'Zea mays L.', rank: 'SPECIES'};
const mexicana = {key: 2, canonicalName: 'Zea mexicana', scientificName: 'Zea mexicana (Schrad.) Kuntze', rank: 'SPECIES'};

function stubSuggestions(matches) {
  const fetch = vi.fn(async () => ({ok: true, status: 200, json: async () => matches}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

// The field is controlled by its form, so give it somewhere to keep its value.
function Field({initial}) {
  const [value, setValue] = useState(initial);
  return <GbifNameInput id="sci_name[1]" name="sci_name[1]" value={value} onChange={setValue} url="/gbif" />;
}

function setup(initial = '') {
  const user = userEvent.setup();
  render(<Field initial={initial} />);
  return {user, input: screen.getByRole('combobox')};
}

describe('GbifNameInput', () => {
  it('does not search for a name already on the form', async () => {
    const fetch = stubSuggestions([maize]);
    setup('Zea mays');
    await new Promise((resolve) => setTimeout(resolve, 400));
    expect(fetch).not.toHaveBeenCalled();
  });

  it('does not search for fewer than three letters', async () => {
    const fetch = stubSuggestions([maize]);
    const {user, input} = setup();
    await user.type(input, 'Ze');
    await new Promise((resolve) => setTimeout(resolve, 400));
    expect(fetch).not.toHaveBeenCalled();
  });

  it('searches the given url for what is typed', async () => {
    const fetch = stubSuggestions([maize]);
    const {user, input} = setup();
    await user.type(input, 'Zea');
    await screen.findByRole('option');
    expect(fetch).toHaveBeenLastCalledWith('/gbif?term=Zea', expect.anything());
  });

  it('lists each match with its scientific name and rank', async () => {
    stubSuggestions([maize]);
    const {user, input} = setup();
    await user.type(input, 'Zea');
    expect(await screen.findByRole('option')).toHaveTextContent('Zea mays (Zea mays L.) – SPECIES');
  });

  it('fills in the canonical name of a match clicked', async () => {
    stubSuggestions([maize, mexicana]);
    const {user, input} = setup();
    await user.type(input, 'Zea');
    await user.click(await screen.findByRole('option', {name: /Zea mexicana/}));
    expect(input).toHaveValue('Zea mexicana');
  });

  it('closes the list once a match is chosen', async () => {
    stubSuggestions([maize, mexicana]);
    const {user, input} = setup();
    await user.type(input, 'Zea');
    await user.click(await screen.findByRole('option', {name: /Zea mexicana/}));
    expect(screen.queryByRole('option')).not.toBeInTheDocument();
  });

  it('does not search again for a name just chosen', async () => {
    const fetch = stubSuggestions([maize]);
    const {user, input} = setup();
    await user.type(input, 'Zea');
    await user.click(await screen.findByRole('option'));
    await new Promise((resolve) => setTimeout(resolve, 400));
    expect(fetch).toHaveBeenCalledTimes(1);
  });

  it('chooses the highlighted match with the arrow keys and Enter', async () => {
    stubSuggestions([maize, mexicana]);
    const {user, input} = setup();
    await user.type(input, 'Zea');
    await screen.findAllByRole('option');
    await user.keyboard('{ArrowDown}{ArrowDown}{Enter}');
    expect(input).toHaveValue('Zea mexicana');
  });

  it('leaves what was typed alone when Enter is pressed with nothing highlighted', async () => {
    stubSuggestions([maize]);
    const {user, input} = setup();
    await user.type(input, 'Zea');
    await screen.findByRole('option');
    await user.keyboard('{Enter}');
    expect(input).toHaveValue('Zea');
  });

  it('closes the list with Escape', async () => {
    stubSuggestions([maize]);
    const {user, input} = setup();
    await user.type(input, 'Zea');
    await screen.findByRole('option');
    await user.keyboard('{Escape}');
    expect(screen.queryByRole('option')).not.toBeInTheDocument();
  });

  it('closes the list when the field loses focus', async () => {
    stubSuggestions([maize]);
    const {user, input} = setup();
    await user.type(input, 'Zea');
    await screen.findByRole('option');
    await user.tab();
    expect(screen.queryByRole('option')).not.toBeInTheDocument();
  });
});
