import {act, render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import {GARDEN_CARD_CHANGED} from '../nurseryPanel';
import GardenCards from './GardenCards';

vi.mock('./PlantSomethingModal', () => ({
  default: ({garden, onCreated}) => (
    <div role="dialog" aria-label={`Plant in ${garden.name}`}>
      <button type="button" onClick={() => onCreated({...garden, plantings_count: 1, annuals: [{id: 9, crop: {name: 'Kale'}, url: '/p/9', actions: [], badges: [], harvests: [], percentage_grown: null}]}, {name: 'Kale'})}>Plant</button>
    </div>
  ),
}));
vi.mock('./GardenFormModal', () => ({
  default: ({garden, onSaved}) => (
    <div role="dialog" aria-label={`Edit ${garden.name}`}>
      <button type="button" onClick={() => onSaved({...garden, active: false})}>Deactivate</button>
    </div>
  ),
}));

const garden = (id, name) => ({
  id, name, url: `/gardens/${id}`, image_url: '/g.jpg', layout_url: null, plant_url: `/plantings/new?garden_id=${id}`,
  plantings_count: 0, harvesting_now: 0, owner: {login_name: 'sam'}, active: true,
  actions: [{key: 'edit', label: 'Edit', href: `/gardens/${id}/edit`}], perennials: [], annuals: [],
});

function setup() {
  render(<GardenCards gardens={[garden(1, 'Front'), garden(2, 'Back')]} default_icon_url="/d.png" />);
}

describe('GardenCards', () => {
  it('shows a card for each garden', () => {
    setup();
    expect(screen.getAllByText(/^(Front|Back)$/, {selector: 'b'})).toHaveLength(2);
  });

  it('opens the first card only', () => {
    const {container} = render(<GardenCards gardens={[garden(1, 'Front'), garden(2, 'Back')]} default_icon_url="/d.png" />);
    expect(container.querySelectorAll('details[open]')).toHaveLength(1);
  });

  it('opens the plant dialog for the garden', async () => {
    setup();
    await userEvent.click(screen.getAllByRole('link', {name: /Add planting/})[1]);
    expect(screen.getByRole('dialog', {name: 'Plant in Back'})).toBeInTheDocument();
  });

  it('says what was planted', async () => {
    setup();
    await userEvent.click(screen.getAllByRole('link', {name: /Add planting/})[0]);
    await userEvent.click(screen.getByRole('button', {name: 'Plant'}));
    expect(screen.getByRole('status')).toHaveTextContent('Planted Kale in Front.');
  });

  it('closes the plant dialog once planted', async () => {
    setup();
    await userEvent.click(screen.getAllByRole('link', {name: /Add planting/})[0]);
    await userEvent.click(screen.getByRole('button', {name: 'Plant'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('shows the new planting without a reload', async () => {
    setup();
    await userEvent.click(screen.getAllByRole('link', {name: /Add planting/})[0]);
    await userEvent.click(screen.getByRole('button', {name: 'Plant'}));
    expect(screen.getByRole('link', {name: /Kale/})).toBeInTheDocument();
  });

  it('dismisses the notice', async () => {
    setup();
    await userEvent.click(screen.getAllByRole('link', {name: /Add planting/})[0]);
    await userEvent.click(screen.getByRole('button', {name: 'Plant'}));
    await userEvent.click(screen.getByRole('button', {name: 'Dismiss'}));
    expect(screen.queryByRole('status')).not.toBeInTheDocument();
  });

  it('removes a garden that was made inactive', async () => {
    setup();
    await userEvent.click(screen.getAllByRole('link', {name: 'Edit'})[0]);
    await userEvent.click(screen.getByRole('button', {name: 'Deactivate'}));
    expect(screen.queryByText('Front', {selector: 'b'})).not.toBeInTheDocument();
  });

  it('says the garden is now inactive', async () => {
    setup();
    await userEvent.click(screen.getAllByRole('link', {name: 'Edit'})[0]);
    await userEvent.click(screen.getByRole('button', {name: 'Deactivate'}));
    expect(screen.getByRole('status')).toHaveTextContent('Front is now inactive');
  });

  it('takes a garden\'s new card sent from elsewhere on the page', () => {
    setup();
    act(() => {
      window.dispatchEvent(new CustomEvent(GARDEN_CARD_CHANGED, {detail: {...garden(1, 'Front'), name: 'Front yard'}}));
    });
    expect(screen.getByText('Front yard', {selector: 'b'})).toBeInTheDocument();
  });

  it('keeps the owner when it takes a new card', () => {
    const withoutOwner = {...garden(1, 'Front yard'), owner: undefined};
    setup();
    act(() => {
      window.dispatchEvent(new CustomEvent(GARDEN_CARD_CHANGED, {detail: withoutOwner}));
    });
    expect(screen.getAllByText(/owner: sam/)).toHaveLength(2);
  });
});
