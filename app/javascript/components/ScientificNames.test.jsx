import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import ScientificNames from './ScientificNames';

describe('ScientificNames', () => {
  it('shows the existing names as fields named sci_name[N]', () => {
    render(<ScientificNames names={['Zea mays']} suggest_url="/gbif" />);
    expect(screen.getByLabelText('Scientific name 1:')).toHaveAttribute('name', 'sci_name[1]');
  });

  it('shows a blank field for a new crop', () => {
    render(<ScientificNames names={[null]} suggest_url="/gbif" />);
    expect(screen.getByLabelText('Scientific name 1:')).toHaveValue('');
  });

  it('suggests names from the url it is given', async () => {
    const fetch = vi.fn(async () => ({ok: true, status: 200, json: async () => []}));
    vi.stubGlobal('fetch', fetch);
    render(<ScientificNames names={['']} suggest_url="/scientific_names/gbif_suggest" />);
    await userEvent.setup().type(screen.getByLabelText('Scientific name 1:'), 'Zea');
    await vi.waitFor(() => expect(fetch).toHaveBeenCalledWith('/scientific_names/gbif_suggest?term=Zea', expect.anything()));
  });
});
