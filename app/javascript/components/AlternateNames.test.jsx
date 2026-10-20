import {render, screen} from '@testing-library/react';
import {describe, expect, it} from 'vitest';

import AlternateNames from './AlternateNames';

describe('AlternateNames', () => {
  it('shows the existing names as text fields', () => {
    render(<AlternateNames names={['Sampaguita']} />);
    expect(screen.getByLabelText('Alternate name 1:')).toHaveValue('Sampaguita');
  });

  it('names the fields alt_name[N]', () => {
    render(<AlternateNames names={['Sampaguita']} />);
    expect(screen.getByLabelText('Alternate name 1:')).toHaveAttribute('name', 'alt_name[1]');
  });
});
