import {render, screen} from '@testing-library/react';
import {describe, expect, it, vi} from 'vitest';

import PlantingRow from './PlantingRow';

const base = {
  id: 1, url: '/plantings/1', crop: {name: 'Tomato', icon_url: '/t.png'}, actions: [], can_edit: false, planted_at: null,
  thumb_url: null, badges: [], progress_note: null,
  timeline: {
    state: 'growing', fill: 40, today: 40, expected_label: 'expected', today_label: 'Today',
    events: [
      {kind: 'sown', label: 'Sown', date: '2025-06-01', expected: false, percent: 0, modifiers: ['above', 'start'], icon_url: '/planting.svg'},
      {kind: 'first_harvest', label: 'First harvest', date: '2025-07-20', expected: true, percent: 60, modifiers: ['below', 'middle', 'expected'], icon_url: '/harvest.svg'},
      {kind: 'finished', label: 'Finished', date: '2025-08-30', expected: true, percent: 100, modifiers: ['above', 'end', 'expected'], icon_url: '/finish.svg'},
    ],
  },
};

function setup(planting = {}, props = {}) {
  return render(<PlantingRow planting={{...base, ...planting}} defaultIconUrl="/d.png" onUpdated={vi.fn()} handlers={{}} {...props} />);
}

describe('PlantingRow', () => {
  it('shows the crop', () => {
    setup();
    expect(screen.getByText('Tomato')).toBeInTheDocument();
  });

  it('shows each event on the timeline', () => {
    const {container} = setup();
    expect(container.querySelectorAll('.planting-timeline-event')).toHaveLength(3);
    expect(screen.getByText('First harvest')).toBeInTheDocument();
  });

  it('shows the photo when there is one', () => {
    setup({thumb_url: '/thumb.jpg'});
    expect(screen.getByAltText('Photo of Tomato')).toHaveAttribute('src', '/thumb.jpg');
  });

  it('shows a badge with its title', () => {
    setup({badges: [{kind: 'first_harvest', label: 'Harvesting', title: 'Has been harvested'}]});
    expect(screen.getByText('Harvesting')).toHaveAttribute('title', 'Has been harvested');
  });

  describe('with a note instead of a timeline', () => {
    it('shows the note', () => {
      setup({timeline: null, progress_note: 'No prediction yet'});
      expect(screen.getByText('No prediction yet')).toBeInTheDocument();
    });

    it('shows no timeline', () => {
      const {container} = setup({timeline: null, progress_note: 'No prediction yet'});
      expect(container.querySelector('.planting-timeline')).toBeNull();
    });
  });

  describe('with nothing to draw and no note', () => {
    it('shows neither', () => {
      const {container} = setup({timeline: null});
      expect(container.querySelector('.planting-timeline')).toBeNull();
      expect(container.querySelector('.planting-row-note')).toBeNull();
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
