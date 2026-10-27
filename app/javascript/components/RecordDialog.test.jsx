import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';

import RecordDialog from './RecordDialog';

vi.mock('./CropPicker', () => ({default: () => null}));
vi.mock('./RecordHarvestModal', () => ({
  default: ({crop}) => <div role="dialog" aria-label={`Harvest ${crop.name}`} />,
}));
vi.mock('./SaveSeedsModal', () => ({
  default: ({crop, source}) => <div role="dialog" aria-label={`Seeds ${crop.name} ${source}`} />,
}));

const plantings = [{id: 1, crop: {id: 2, name: 'Tomato'}}];

function links() {
  render(
    <>
      <RecordDialog plantings_url="/planting_picker.json" />
      <a href="/seeds/new" data-record-dialog="seeds" data-crop-id="2" data-crop-name="Tomato">Add tomato seeds</a>
      <a href="/seeds/new" data-record-dialog="seeds">Add seeds</a>
      <a href="/harvests/new" data-record-dialog="harvest" data-crop-id="5" data-crop-name="Kale">Harvest kale</a>
    </>,
  );
}

describe('RecordDialog', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn(async () => ({ok: true, json: async () => plantings})));
  });

  afterEach(() => vi.unstubAllGlobals());

  it('starts closed', () => {
    links();
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('asks where the seeds came from', async () => {
    links();
    await userEvent.click(screen.getByRole('link', {name: 'Add seeds'}));
    expect(await screen.findByRole('dialog', {name: 'Where did these seeds come from?'})).toBeInTheDocument();
  });

  it('skips asking for the crop when the link names one', async () => {
    links();
    await userEvent.click(screen.getByRole('link', {name: 'Add tomato seeds'}));
    await userEvent.click(await screen.findByRole('button', {name: 'Seeds I bought'}));
    expect(screen.getByRole('dialog', {name: 'Seeds Tomato bought'})).toBeInTheDocument();
  });

  it('goes straight to the harvest when the crop has no plantings', async () => {
    links();
    await userEvent.click(screen.getByRole('link', {name: 'Harvest kale'}));
    expect(await screen.findByRole('dialog', {name: 'Harvest Kale'})).toBeInTheDocument();
  });

  it('follows the link when the plantings do not load', async () => {
    fetch.mockResolvedValue({ok: false, json: async () => null});
    const location = {href: ''};
    vi.stubGlobal('location', location);
    links();
    await userEvent.click(screen.getByRole('link', {name: 'Add seeds'}));
    await waitFor(() => expect(location.href).toBe('/seeds/new'));
  });
});
