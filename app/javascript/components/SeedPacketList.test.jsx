import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import SeedPacketList from './SeedPacketList';

const packets = [
  {id: 1, name: 'Roma tomato', saved: '2024', quantity: 20, heirloom: 'heirloom', plant_before: null, photo_url: '/roma.jpg'},
  {id: 2, name: 'Curly kale', saved: '2022', quantity: null, heirloom: 'hybrid', plant_before: '2023-12-31'},
  {id: 3, name: 'Cherry tomato', saved: '2025', quantity: 5, heirloom: null, plant_before: null},
];

function setup(props = {}) {
  const onChoose = vi.fn();
  const onSearch = vi.fn();
  render(<SeedPacketList packets={packets} search="" onSearch={onSearch} selected={null} onChoose={onChoose} sownOn="2025-06-01" {...props} />);
  return {onChoose, onSearch};
}

describe('SeedPacketList', () => {
  it('lists packets that have not expired', () => {
    setup();
    expect(screen.getAllByRole('button', {name: /tomato/})).toHaveLength(2);
  });

  it('hides expired packets', () => {
    setup();
    expect(screen.queryByRole('button', {name: /kale/})).not.toBeInTheDocument();
  });

  it('says how many are hidden', () => {
    setup();
    expect(screen.getByRole('status')).toHaveTextContent('1 expired packet is hidden.');
  });

  it('shows expired packets when asked', async () => {
    setup();
    await userEvent.click(screen.getByLabelText('Include expired seeds'));
    expect(screen.getByRole('button', {name: /kale/})).toBeInTheDocument();
  });

  it('badges an expired packet with its year', async () => {
    setup();
    await userEvent.click(screen.getByLabelText('Include expired seeds'));
    expect(screen.getByText('Expired 2023')).toBeInTheDocument();
  });

  it('badges heirlooms', () => {
    setup();
    expect(screen.getByText('Heirloom')).toBeInTheDocument();
  });

  it('shows the quantity when known', () => {
    setup();
    expect(screen.getByText('Saved 2024 · 20 seeds')).toBeInTheDocument();
  });

  it('shows the photo of a packet that has one', () => {
    setup();
    expect(screen.getByAltText('Photo of the Roma tomato packet')).toBeInTheDocument();
  });

  it('chooses a packet', async () => {
    const {onChoose} = setup();
    await userEvent.click(screen.getByRole('button', {name: /Roma/}));
    expect(onChoose).toHaveBeenCalledWith(packets[0]);
  });

  it('marks the chosen packet', () => {
    setup({selected: packets[0]});
    expect(screen.getByRole('button', {name: /Roma/})).toHaveAttribute('aria-pressed', 'true');
  });

  it('reports what is typed in the search', async () => {
    const {onSearch} = setup();
    await userEvent.type(screen.getByLabelText('Search your seeds'), 'k');
    expect(onSearch).toHaveBeenCalledWith('k');
  });

  describe('with a search', () => {
    it('shows only packets with that in the name', () => {
      setup({search: 'cherry'});
      expect(screen.getAllByRole('button', {name: /tomato/})).toHaveLength(1);
    });

    it('says how many match', () => {
      setup({search: 'cherry'});
      expect(screen.getByRole('status')).toHaveTextContent('1 of 3 packets match.');
    });
  });

  describe('when nothing matches', () => {
    it('suggests adding new seeds', () => {
      setup({search: 'zzz'});
      expect(screen.getByText(/No seed packets match/)).toBeInTheDocument();
    });
  });

  describe('when the chosen packet has expired', () => {
    it('shows expired packets to start with', () => {
      setup({selected: packets[1]});
      expect(screen.getByLabelText('Include expired seeds')).toBeChecked();
    });
  });
});
