import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import GardenCard from './GardenCard';

const planting = (id, name, extra = {}) => ({
  id, url: `/plantings/${id}`, crop: {name, icon_url: '/i.png'}, actions: [], can_edit: false, planted_at: null,
  badges: [], progress_note: null, percentage_grown: null, harvests: [], ...extra,
});
const garden = {
  id: 1, name: 'Back yard', url: '/gardens/back-yard', image_url: '/g.jpg', layout_url: '/gardens/back-yard/layout',
  plant_url: '/plantings/new?garden_id=1', plantings_count: 2, harvesting_now: 1, owner: null,
  actions: [{key: 'edit', label: 'Edit', href: '/gardens/back-yard/edit'}, {key: 'photo', label: 'Add photo', href: '/photos/new?type=garden&id=1'}],
  perennials: [planting(1, 'Rhubarb')], annuals: [planting(2, 'Tomato')],
};

function setup(props = {}, gardenProps = {}) {
  return render(<GardenCard garden={{...garden, ...gardenProps}} defaultIconUrl="/d.png" {...props} />);
}

describe('GardenCard', () => {
  it('shows the garden\'s name', () => {
    setup();
    expect(screen.getByText('Back yard', {selector: 'b'})).toBeInTheDocument();
  });

  it('summarises the plantings and harvests', () => {
    setup();
    expect(screen.getByText('2 plantings · harvesting now: 1')).toBeInTheDocument();
  });

  it('says planting, singular', () => {
    setup({}, {plantings_count: 1, harvesting_now: 0});
    expect(screen.getByText('1 planting')).toBeInTheDocument();
  });

  it('names the owner on a garden that is not yours', () => {
    setup({}, {owner: {login_name: 'sam'}});
    expect(screen.getByText(/owner: sam/)).toBeInTheDocument();
  });

  it('opens when asked', () => {
    const {container} = setup({defaultOpen: true});
    expect(container.querySelector('details')).toHaveAttribute('open');
  });

  it('lists perennials', () => {
    setup();
    expect(screen.getByRole('link', {name: /Rhubarb/})).toHaveAttribute('href', '/plantings/1');
  });

  it('links to the garden', () => {
    setup();
    expect(screen.getByRole('link', {name: 'Open Back yard ›'})).toHaveAttribute('href', '/gardens/back-yard');
  });

  it('links to the layout', () => {
    setup();
    expect(screen.getByRole('link', {name: /Layout/})).toHaveAttribute('href', '/gardens/back-yard/layout');
  });

  it('leaves out the layout button without a layout', () => {
    setup({}, {layout_url: null});
    expect(screen.queryByRole('link', {name: /Layout/})).not.toBeInTheDocument();
  });

  it('leaves out Add planting for a garden you cannot plant in', () => {
    setup({}, {plant_url: null});
    expect(screen.queryByRole('link', {name: /Add planting/})).not.toBeInTheDocument();
  });

  it('opens the plant dialog from Add planting', async () => {
    const onPlant = vi.fn();
    setup({onPlant});
    await userEvent.click(screen.getByRole('link', {name: /Add planting/}));
    expect(onPlant).toHaveBeenCalledWith(expect.objectContaining({id: 1}));
  });

  it('opens the edit dialog from the garden menu', async () => {
    const onEditGarden = vi.fn();
    setup({onEditGarden});
    await userEvent.click(screen.getByRole('link', {name: 'Edit'}));
    expect(onEditGarden).toHaveBeenCalledWith(expect.objectContaining({id: 1}));
  });

  it('opens the photo dialog from the garden menu', async () => {
    const onAddPhoto = vi.fn();
    setup({onAddPhoto});
    await userEvent.click(screen.getByRole('link', {name: 'Add photo'}));
    expect(onAddPhoto).toHaveBeenCalledWith({label: 'Back yard garden', href: '/photos/new?type=garden&id=1'});
  });

  describe('with nothing planted', () => {
    it('says so', () => {
      setup({}, {perennials: [], annuals: []});
      expect(screen.getByText('Nothing planted here yet.')).toBeInTheDocument();
    });
  });

  describe('without perennials', () => {
    it('says none', () => {
      setup({}, {perennials: []});
      expect(screen.getByText('None')).toBeInTheDocument();
    });
  });
});
