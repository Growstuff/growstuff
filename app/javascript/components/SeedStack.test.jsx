import {act, render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import SeedStack from './SeedStack';

const props = {
  crop: {name: 'Tomato', path: '/crops/tomato'},
  count: 2,
  image_url: '/t.jpg',
  heirloom: 'heirloom',
  rule: 'Sow in spring',
  owner: null,
  packets: [
    {id: 1, name: 'Roma', path: '/seeds/1', image_url: '/1.jpg', when: 'Saved 2024', detail: '20 seeds', rule: 'Sow in spring', heirloom: 'heirloom', past: false},
    {id: 2, name: 'Cherry', path: '/seeds/2', image_url: '/2.jpg', when: 'Saved 2020', detail: '5 seeds', rule: 'Sow in spring', heirloom: null, past: true},
  ],
};

const pile = () => screen.getByRole('button', {name: 'Tomato, 2 packets. Open to see each packet'});

describe('SeedStack', () => {
  it('starts as a closed pile', () => {
    render(<SeedStack {...props} />);
    expect(pile()).toHaveAttribute('aria-expanded', 'false');
  });

  it('shows the count on the pile', () => {
    render(<SeedStack {...props} />);
    expect(screen.getByText('×2')).toBeInTheDocument();
  });

  it('shows the heirloom pill', () => {
    render(<SeedStack {...props} />);
    expect(screen.getByText('Heirloom')).toBeInTheDocument();
  });

  it('shows whose it is on a page of other people\'s seeds', () => {
    render(<SeedStack {...props} owner={{path: '/members/sam', label: 'Sam\'s seeds', tag: 'Sam', avatar_url: '/sam.png'}} />);
    expect(screen.getByRole('link', {name: 'Sam\'s seeds'})).toHaveAttribute('href', '/members/sam');
  });

  describe('when opened', () => {
    async function open() {
      render(<SeedStack {...props} />);
      await userEvent.click(pile());
    }

    it('spreads out a packet each', async () => {
      await open();
      expect(screen.getAllByRole('article')).toHaveLength(2);
    });

    it('links each packet', async () => {
      await open();
      expect(screen.getByRole('link', {name: 'Roma'})).toHaveAttribute('href', '/seeds/1');
    });

    it('stamps packets past their sow-by date', async () => {
      await open();
      expect(screen.getAllByText('Past sow-by')).toHaveLength(1);
    });

    it('links to the crop page', async () => {
      await open();
      expect(screen.getByRole('link', {name: /Open the Tomato page/})).toHaveAttribute('href', '/crops/tomato');
    });

    it('is a group named for the pile', async () => {
      await open();
      expect(screen.getByRole('group', {name: 'Tomato, 2 packets'})).toBeInTheDocument();
    });
  });

  describe('when closed again', () => {
    it('folds back into a pile after the animation', async () => {
      vi.useFakeTimers({shouldAdvanceTime: true});
      render(<SeedStack {...props} />);
      await userEvent.click(pile());
      await userEvent.click(screen.getByRole('button', {name: /Close/}));
      act(() => vi.advanceTimersByTime(300));
      expect(pile()).toBeInTheDocument();
    });

    it('closes on Escape', async () => {
      vi.useFakeTimers({shouldAdvanceTime: true});
      render(<SeedStack {...props} />);
      await userEvent.click(pile());
      screen.getByRole('button', {name: /Close/}).focus();
      await userEvent.keyboard('{Escape}');
      act(() => vi.advanceTimersByTime(300));
      expect(pile()).toBeInTheDocument();
    });
  });
});
