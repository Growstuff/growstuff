import {render, screen} from '@testing-library/react';
import {describe, expect, it, vi} from 'vitest';

import PlantingRow from './PlantingRow';

const base = {
  id: 1, url: '/plantings/1', crop: {name: 'Tomato', icon_url: '/t.png'}, actions: [], can_edit: false, planted_at: null,
  thumb_url: null, badges: [], progress_note: null, percentage_grown: 50, progress_state: 'growing',
  finish_predicted_label: 'Ready in 3 weeks', harvests: [],
};

function setup(planting = {}, props = {}) {
  return render(<PlantingRow planting={{...base, ...planting}} defaultIconUrl="/d.png" onUpdated={vi.fn()} handlers={{}} {...props} />);
}

describe('PlantingRow', () => {
  it('shows the crop', () => {
    setup();
    expect(screen.getByText('Tomato')).toBeInTheDocument();
  });

  it('shows the progress', () => {
    setup();
    expect(screen.getByRole('progressbar')).toHaveAttribute('aria-valuenow', '50');
  });

  it('shows the percentage', () => {
    setup();
    expect(screen.getByText('50%')).toBeInTheDocument();
  });

  it('shows when it will finish', () => {
    setup();
    expect(screen.getByText('Ready in 3 weeks')).toBeInTheDocument();
  });

  it('shows the photo when there is one', () => {
    setup({thumb_url: '/thumb.jpg'});
    expect(screen.getByAltText('Photo of Tomato')).toHaveAttribute('src', '/thumb.jpg');
  });

  it('shows a badge with its title', () => {
    setup({badges: [{kind: 'first_harvest', label: 'Harvesting', title: 'Has been harvested'}]});
    expect(screen.getByText('Harvesting')).toHaveAttribute('title', 'Has been harvested');
  });

  describe('with a note instead of a prediction', () => {
    it('shows the note', () => {
      setup({progress_note: 'No prediction yet'});
      expect(screen.getByText('No prediction yet')).toBeInTheDocument();
    });

    it('shows no progress bar', () => {
      setup({progress_note: 'No prediction yet'});
      expect(screen.queryByRole('progressbar')).not.toBeInTheDocument();
    });
  });

  describe('with nothing to predict from', () => {
    it('shows no progress bar', () => {
      setup({percentage_grown: null});
      expect(screen.queryByRole('progressbar')).not.toBeInTheDocument();
    });
  });

  describe('with harvests', () => {
    const harvests = [{date: '2025-06-01', percent: 30}, {date: '2025-07-01', percent: 60}];

    it('ticks each one on the bar', () => {
      const {container} = setup({harvests});
      expect(container.querySelectorAll('.harvest-tick')).toHaveLength(2);
    });

    it('says how many for assistive technology', () => {
      setup({harvests});
      expect(screen.getByText(/2 harvests, the latest on/)).toBeInTheDocument();
    });
  });

  describe('when highlighted', () => {
    it('is marked as just added', () => {
      const {container} = setup({}, {highlighted: true});
      expect(container.firstChild).toHaveClass('planting-just-added');
    });

    it('says a harvest was recorded', () => {
      setup({}, {highlighted: true, highlightKind: 'harvested'});
      expect(screen.getByText('Harvest recorded')).toBeInTheDocument();
    });
  });
});
