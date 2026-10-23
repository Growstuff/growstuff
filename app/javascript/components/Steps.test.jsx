import {render, screen} from '@testing-library/react';
import {describe, expect, it} from 'vitest';

import Steps from './Steps';

function setup(current) {
  render(<Steps steps={['Crop', 'Where', 'When']} current={current} />);
}

describe('Steps', () => {
  it('lists every step', () => {
    setup(2);
    expect(screen.getAllByRole('listitem')).toHaveLength(3);
  });

  it('marks the current step for assistive technology', () => {
    setup(2);
    expect(screen.getByText('Where', {selector: 'li'})).toHaveAttribute('aria-current', 'step');
  });

  it('does not mark other steps as current', () => {
    setup(2);
    expect(screen.getByText('Crop', {selector: 'li'})).not.toHaveAttribute('aria-current');
  });

  it('styles earlier steps as done', () => {
    setup(2);
    expect(screen.getByText('Crop', {selector: 'li'})).toHaveClass('plant-step-done');
  });

  it('says earlier steps are done', () => {
    setup(2);
    expect(screen.getByText('(done)')).toBeInTheDocument();
  });

  it('styles later steps as todo', () => {
    setup(2);
    expect(screen.getByText('When', {selector: 'li'})).toHaveClass('plant-step-todo');
  });

  it('numbers steps that are not done', () => {
    setup(2);
    expect(screen.getByText('3')).toBeInTheDocument();
  });
});
