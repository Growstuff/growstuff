import {act, render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, describe, expect, it, vi} from 'vitest';

import PlantingActions from './PlantingActions';

vi.mock('./EditPlantingModal', () => ({default: ({onSaved}) => <div role="dialog" aria-label="Edit"><button type="button" onClick={() => onSaved()}>Save</button></div>}));
vi.mock('./RecordHarvestModal', () => ({default: () => <div role="dialog" aria-label="Harvest" />}));
vi.mock('./SaveSeedsModal', () => ({default: () => <div role="dialog" aria-label="Seeds" />}));
vi.mock('./MarkFinishedModal', () => ({default: () => <div role="dialog" aria-label="Finish" />}));
vi.mock('./AddPhotoModal', () => ({default: ({label, newUrl}) => <div role="dialog" aria-label={label} data-url={newUrl} />}));

const planting = {id: 1, crop: {name: 'Tomato'}};
const actions = [
  {key: 'edit', label: 'Edit', href: '/plantings/1/edit'},
  {key: 'harvest', label: 'Harvest', href: '/harvests/new'},
  {key: 'seeds', label: 'Save seeds', href: '/seeds/new'},
  {key: 'finish', label: 'Mark finished', href: '/finish'},
  {key: 'photo', label: 'Add photo', href: '/photos/new?type=planting&id=1'},
  {key: 'transplant', label: 'Transplant', href: '/transplant'},
  {key: 'delete', label: 'Delete', href: '/plantings/1', method: 'delete', confirm: 'Sure?'},
];

function setup(props = {}) {
  return render(<PlantingActions planting={planting} actions={actions} {...props} />);
}

describe('PlantingActions', () => {
  afterEach(() => {
    delete window.bootstrap;
  });

  it('has an actions button', () => {
    setup();
    expect(screen.getByRole('button', {name: 'Actions'})).toBeInTheDocument();
  });

  it('lists the actions the server allows', () => {
    setup();
    expect(screen.getAllByRole('link')).toHaveLength(7);
  });

  it.each([
    ['Edit', 'Edit'],
    ['Harvest', 'Harvest'],
    ['Save seeds', 'Seeds'],
    ['Mark finished', 'Finish'],
    ['Add photo', 'Tomato planting'],
  ])('opens a dialog for %s', async (item, dialog) => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: item}));
    expect(screen.getByRole('dialog', {name: dialog})).toBeInTheDocument();
  });

  it('gives the photo dialog the link it was opened from', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Add photo'}));
    expect(screen.getByRole('dialog')).toHaveAttribute('data-url', '/photos/new?type=planting&id=1');
  });

  it('keeps delete as a link, for jquery_ujs', async () => {
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Delete'}));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('shows the server-rendered transplant dialog', async () => {
    const show = vi.fn();
    window.bootstrap = {Modal: {getOrCreateInstance: vi.fn(() => ({show}))}, Dropdown: {getInstance: vi.fn()}};
    const dialog = document.createElement('div');
    dialog.id = 'transplant-modal';
    document.body.appendChild(dialog);
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Transplant'}));
    dialog.remove();
    expect(show).toHaveBeenCalledTimes(1);
  });

  it('opens a dialog from a section heading\'s add link', async () => {
    render(
        <>
          <a href="/harvests/new" data-planting-dialog="harvest">add</a>
          <PlantingActions planting={planting} actions={actions} />
        </>,
    );
    await userEvent.click(screen.getByRole('link', {name: 'add'}));
    expect(screen.getByRole('dialog', {name: 'Harvest'})).toBeInTheDocument();
  });

  it('closes the dialog and reloads the page once saved', async () => {
    vi.useFakeTimers({shouldAdvanceTime: true});
    const reload = vi.fn();
    vi.stubGlobal('location', {...window.location, reload});
    setup();
    await userEvent.click(screen.getByRole('link', {name: 'Edit'}));
    await userEvent.click(screen.getByRole('button', {name: 'Save'}));
    act(() => vi.advanceTimersByTime(10));
    expect(reload).toHaveBeenCalledTimes(1);
  });

  describe('without actions', () => {
    it('draws nothing', () => {
      const {container} = setup({actions: []});
      expect(container).toBeEmptyDOMElement();
    });
  });
});
