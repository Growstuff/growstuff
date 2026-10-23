import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it} from 'vitest';

import HarvestChart from './HarvestChart';

const measures = [
  {key: 'count', label: 'Count', note: 'How many', unit: 'items'},
  {key: 'weight', label: 'Weight', note: 'How heavy', unit: 'kg'},
];
const months = [
  {month: 1, label: 'Jan', count: {this_year: 10, last_year: 5}, weight: {this_year: 1, last_year: 2}},
  {month: 2, label: 'Feb', count: {this_year: 0, last_year: 2.55}, weight: {this_year: 0, last_year: 0}},
];

function setup() {
  return render(<HarvestChart months={months} current_month={2} measures={measures} />);
}

describe('HarvestChart', () => {
  it('shows the first measure first', () => {
    setup();
    expect(screen.getByText('How many')).toBeInTheDocument();
  });

  it('labels each month', () => {
    setup();
    expect(screen.getByText('Jan')).toBeInTheDocument();
  });

  it('marks the current month', () => {
    setup();
    expect(screen.getByText('Feb')).toHaveClass('now');
  });

  it('scales the tallest bar to full height', () => {
    const {container} = setup();
    expect(container.querySelector('.this-year')).toHaveStyle({height: '100%'});
  });

  it('scales other bars against the tallest', () => {
    const {container} = setup();
    expect(container.querySelector('.last-year')).toHaveStyle({height: '50%'});
  });

  it('titles bars with the total and unit', () => {
    const {container} = setup();
    expect(container.querySelector('.this-year')).toHaveAttribute('title', '10 items');
  });

  it('rounds totals in titles to one decimal', () => {
    const {container} = setup();
    expect(container.querySelectorAll('.last-year')[1]).toHaveAttribute('title', '2.6 items');
  });

  describe('when another measure is chosen', () => {
    it('shows its note', async () => {
      setup();
      await userEvent.click(screen.getByText('Weight'));
      expect(screen.getByText('How heavy')).toBeInTheDocument();
    });

    it('uses its unit', async () => {
      const {container} = setup();
      await userEvent.click(screen.getByText('Weight'));
      expect(container.querySelector('.this-year')).toHaveAttribute('title', '1 kg');
    });
  });
});
