import {render, screen} from '@testing-library/react';
import {describe, expect, it} from 'vitest';

import PlantingTimeline from './PlantingTimeline';

const timeline = {
  state: 'harvesting', fill: 55, today: 55, expected_label: 'expected', today_label: 'Today',
  events: [
    {kind: 'sown', label: 'Sown', date: '2025-06-01', expected: false, percent: 0, modifiers: ['above', 'start'], icon_url: '/planting.svg'},
    {kind: 'transplanted', label: 'Moved to Bed 2', date: '2025-06-20', expected: false, percent: 20, modifiers: ['below', 'middle'], icon_url: '/growing.svg'},
    {kind: 'first_harvest', label: 'First harvest', date: '2025-07-20', expected: true, percent: 60, modifiers: ['above', 'middle', 'expected'], icon_url: '/harvest.svg'},
    {kind: 'failed', label: 'Failed', date: '2025-08-30', expected: false, percent: 100, modifiers: ['below', 'end', 'failed'], icon_url: '/finish.svg'},
  ],
};

describe('PlantingTimeline', () => {
  it('lists the events in order, each with its label', () => {
    render(<PlantingTimeline timeline={timeline} />);
    const names = screen.getAllByRole('listitem').map((item) => item.querySelector('.planting-timeline-name').textContent);
    expect(names).toEqual(['Sown', 'Moved to Bed 2', 'First harvest', 'Failed']);
  });

  it('puts each event at its place on the line', () => {
    render(<PlantingTimeline timeline={timeline} />);
    expect(screen.getAllByRole('listitem')[2]).toHaveStyle({left: '60%'});
  });

  it('gives each event the icon the server chose', () => {
    const {container} = render(<PlantingTimeline timeline={timeline} />);
    expect([...container.querySelectorAll('.planting-timeline-marker img')].map((img) => img.getAttribute('src')))
      .toEqual(['/planting.svg', '/growing.svg', '/harvest.svg', '/finish.svg']);
  });

  it('marks only the expected events as expected', () => {
    render(<PlantingTimeline timeline={timeline} />);
    const items = screen.getAllByRole('listitem');
    expect(items.map((item) => item.classList.contains('planting-timeline-event--expected'))).toEqual([false, false, true, false]);
    expect(items[2]).toHaveTextContent('expected');
  });

  it('puts each label on the side of the line the server chose', () => {
    render(<PlantingTimeline timeline={timeline} />);
    const sides = screen.getAllByRole('listitem').map((item) => (item.classList.contains('planting-timeline-event--above') ? 'above' : 'below'));
    expect(sides).toEqual(['above', 'below', 'above', 'below']);
  });

  it('leans the labels the server says are at either end', () => {
    render(<PlantingTimeline timeline={timeline} />);
    const items = screen.getAllByRole('listitem');
    expect(items[0]).toHaveClass('planting-timeline-event--start');
    expect(items[3]).toHaveClass('planting-timeline-event--end');
  });

  it('shows a failure in the failed style', () => {
    render(<PlantingTimeline timeline={timeline} />);
    expect(screen.getAllByRole('listitem')[3]).toHaveClass('planting-timeline-event--failed');
  });

  it('fills the line as far as today, in the planting\'s state colour', () => {
    const {container} = render(<PlantingTimeline timeline={timeline} />);
    const fill = container.querySelector('.planting-timeline-fill');
    expect(fill).toHaveStyle({width: '55%'});
    expect(fill).toHaveClass('progress-bar--harvesting');
  });

  it('has no marker for today when the planting has finished', () => {
    const {container} = render(<PlantingTimeline timeline={{...timeline, today: null}} />);
    expect(container.querySelector('.planting-timeline-today')).toBeNull();
  });

  it('is compact in a list', () => {
    const {container} = render(<PlantingTimeline timeline={timeline} compact />);
    expect(container.firstChild).toHaveClass('planting-timeline--compact');
  });
});
