import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';

import AnimalDialog from './AnimalDialog';

const formHtml = `
  <form action="/domesticated_animals" method="post">
    <input type="hidden" name="dialog" value="true">
    <label for="rabbit">Rabbit</label>
    <input id="rabbit" type="radio" name="domesticated_animal[category]" value="rabbit">
    <label for="domesticated_animal_name">Name</label>
    <input id="domesticated_animal_name" name="domesticated_animal[name]">
    <label for="domesticated_animal_species">Species</label>
    <input id="domesticated_animal_species" name="domesticated_animal[species]">
    <a href="/members/grower" data-animal-dialog-cancel="true">Cancel</a>
    <button type="submit">Save animal</button>
  </form>`;

function setup() {
  render(<AnimalDialog url="/domesticated_animals/new" label="Add animal" title="Your animal"
    loading_label="Loading" error_label="Please try again" />);
}

async function openForm() {
  setup();
  await userEvent.click(screen.getByRole('link', {name: 'Add animal'}));
  await screen.findByRole('textbox', {name: 'Name'});
}

describe('AnimalDialog', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ok: true, text: async () => formHtml}));
  });

  afterEach(() => vi.unstubAllGlobals());

  it('keeps a standalone link as a fallback', () => {
    setup();
    expect(screen.getByRole('link', {name: 'Add animal'})).toHaveAttribute('href', '/domesticated_animals/new');
  });

  it('opens the form in a dialog', async () => {
    await openForm();
    expect(screen.getByRole('dialog', {name: 'Your animal'})).toBeInTheDocument();
  });

  it('initializes the scientific name suggestions', async () => {
    await openForm();
    await userEvent.click(screen.getByRole('radio', {name: 'Rabbit'}));
    expect(screen.getByRole('textbox', {name: 'Species'})).toHaveValue('Oryctolagus cuniculus domesticus');
  });

  it('closes when cancelled', async () => {
    await openForm();
    await userEvent.click(screen.getByRole('link', {name: 'Cancel'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('closes with Escape', async () => {
    await openForm();
    await userEvent.keyboard('{Escape}');
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('restores focus to the trigger on close', async () => {
    await openForm();
    await userEvent.keyboard('{Escape}');
    expect(screen.getByRole('link', {name: 'Add animal'})).toHaveFocus();
  });

  it('shows server validation errors inside the dialog', async () => {
    await openForm();
    fetch.mockResolvedValue({status: 422, text: async () => formHtml.replace('<form ', '<p role="alert">Invalid details</p><form ')});
    await userEvent.click(screen.getByRole('button', {name: 'Save animal'}));
    expect(await screen.findByRole('alert')).toHaveTextContent('Invalid details');
  });

  it('keeps entered details after a network failure', async () => {
    await openForm();
    await userEvent.type(screen.getByRole('textbox', {name: 'Name'}), 'Clover');
    fetch.mockRejectedValue(new Error('Offline'));
    await userEvent.click(screen.getByRole('button', {name: 'Save animal'}));
    await screen.findByRole('alert');
    expect(screen.getByRole('textbox', {name: 'Name'})).toHaveValue('Clover');
  });

  it('navigates to the animal after saving', async () => {
    const assign = vi.fn();
    vi.stubGlobal('location', {assign});
    await openForm();
    fetch.mockResolvedValue({redirected: true, url: '/domesticated_animals/1'});
    await userEvent.click(screen.getByRole('button', {name: 'Save animal'}));
    await waitFor(() => expect(assign).toHaveBeenCalledWith('/domesticated_animals/1'));
  });

  it('falls back to the full page when the form cannot load', async () => {
    const assign = vi.fn();
    vi.stubGlobal('location', {assign});
    fetch.mockRejectedValue(new Error('Offline'));
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Add animal'}));
    await waitFor(() => expect(assign).toHaveBeenCalledWith('/domesticated_animals/new'));
  });
});
