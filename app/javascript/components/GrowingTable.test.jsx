import {render, screen, within} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it} from 'vitest';

import GrowingTable from './GrowingTable';

const labels = {
  chip_growing: 'Growing', chip_ready: 'Ready', all_plants: 'All plants', all_gardens: 'All gardens',
  col_plant: 'Plant', col_bed: 'Bed', col_planted: 'Planted', col_maturity: 'Maturity', col_progress: 'Progress',
  nothing_to_show: 'Nothing to show',
};
const row = (id, name, extra = {}) => ({id, name, url: `/p/${id}`, image_url: '/i.png', garden: 'Front', garden_id: 1, plant_id: 1, planted: 'May', maturity: 'Aug', progress: 40, ready: false, ...extra});
const rows = [
  row(1, 'Roma', {ready: true}),
  row(2, 'Kale', {plant_id: 2, garden_id: 2}),
  row(3, 'Chard', {plant_id: 3}),
];
const plants = [{id: 1, name: 'Tomato'}, {id: 2, name: 'Kale'}, {id: 3, name: 'Chard'}];
const gardens = [{id: 1, name: 'Front'}, {id: 2, name: 'Back'}];

function setup(props = {}) {
  render(<GrowingTable rows={rows} plants={plants} gardens={gardens} initial="growing" labels={labels} {...props} />);
}

const bodyRows = () => within(screen.getAllByRole('rowgroup')[1]).getAllByRole('row');

describe('GrowingTable', () => {
  it('lists what is growing', () => {
    setup();
    expect(bodyRows()).toHaveLength(3);
  });

  it('counts what is growing on its chip', () => {
    setup();
    expect(screen.getByText('Growing (3)')).toBeInTheDocument();
  });

  it('counts what is ready on its chip', () => {
    setup();
    expect(screen.getByText('Ready (1)')).toBeInTheDocument();
  });

  it('links each plant', () => {
    setup();
    expect(screen.getByRole('link', {name: 'Roma'})).toHaveAttribute('href', '/p/1');
  });

  it('shows only what is ready from the Ready chip', async () => {
    setup();
    await userEvent.click(screen.getByText('Ready (1)'));
    expect(bodyRows()).toHaveLength(1);
  });

  it('starts on the chip it is given', () => {
    setup({initial: 'ready'});
    expect(bodyRows()).toHaveLength(1);
  });

  it('filters by plant', async () => {
    setup();
    await userEvent.selectOptions(screen.getByLabelText('All plants'), 'Kale');
    expect(bodyRows()).toHaveLength(1);
  });

  it('filters by garden', async () => {
    setup();
    await userEvent.selectOptions(screen.getByLabelText('All gardens'), 'Front');
    expect(bodyRows()).toHaveLength(2);
  });

  it('updates the counts when filtered', async () => {
    setup();
    await userEvent.selectOptions(screen.getByLabelText('All gardens'), 'Front');
    expect(screen.getByText('Growing (2)')).toBeInTheDocument();
  });

  it('goes back to all when the all option is chosen', async () => {
    setup();
    await userEvent.selectOptions(screen.getByLabelText('All gardens'), 'Front');
    await userEvent.selectOptions(screen.getByLabelText('All gardens'), 'All gardens');
    expect(bodyRows()).toHaveLength(3);
  });

  it('shows at most ten rows', () => {
    const many = Array.from({length: 12}, (_, i) => row(i + 1, `Plant ${i + 1}`));
    setup({rows: many});
    expect(bodyRows()).toHaveLength(10);
  });

  describe('with only one garden', () => {
    it('has no garden filter', () => {
      setup({gardens: [{id: 1, name: 'Front'}]});
      expect(screen.queryByLabelText('All gardens')).not.toBeInTheDocument();
    });
  });

  describe('with nothing growing', () => {
    it('says so', () => {
      setup({rows: []});
      expect(screen.getByText('Nothing to show')).toBeInTheDocument();
    });
  });
});
