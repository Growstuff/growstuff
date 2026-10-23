import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import NurseryChip from './NurseryChip';

vi.mock('../nurseryPanel', () => ({refreshNursery: vi.fn(), showSaved: vi.fn()}));
vi.mock('./EditPlantingModal', () => ({default: () => <div role="dialog" aria-label="Edit planting" />}));
vi.mock('./TransplantModal', () => ({default: ({gardens}) => <div role="dialog" aria-label={`Transplant into ${gardens.length}`} />}));
vi.mock('./AddPhotoModal', () => ({default: ({label, newUrl}) => <div role="dialog" aria-label={label} data-url={newUrl} />}));

const actions = [
  {key: 'edit', label: 'Edit', href: '/p/1/edit'},
  {key: 'transplant', label: 'Transplant', href: '/p/1/transplant'},
  {key: 'photo', label: 'Add photo', href: '/photos/new?type=planting&id=1'},
];
const planting = {id: 1, url: '/plantings/1', crop: {name: 'Kale', icon_url: '/k.png'}, actions};

function setup(props = {}) {
  render(<NurseryChip planting={planting} default_icon_url="/d.png" photo_icon_url="/p.png" gardens={[{id: 1}, {id: 2}]} {...props} />);
}

describe('NurseryChip', () => {
  it('is the planting\'s chip', () => {
    setup();
    expect(screen.getByRole('button', {name: 'Actions for Kale'})).toBeInTheDocument();
  });

  it('shows how many there are', () => {
    setup({detail: '6 seedlings'});
    expect(screen.getByText('6 seedlings')).toBeInTheDocument();
  });

  it('opens the edit dialog', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Edit'}));
    expect(screen.getByRole('dialog', {name: 'Edit planting'})).toBeInTheDocument();
  });

  it('opens the transplant dialog with the gardens', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Transplant'}));
    expect(screen.getByRole('dialog', {name: 'Transplant into 2'})).toBeInTheDocument();
  });

  it('opens the photo dialog for the planting', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Add photo'}));
    expect(screen.getByRole('dialog', {name: 'Kale planting'})).toHaveAttribute('data-url', '/photos/new?type=planting&id=1');
  });
});
