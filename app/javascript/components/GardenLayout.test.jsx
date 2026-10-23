import {act, createEvent, fireEvent, render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, beforeEach, describe, expect, it, vi} from 'vitest';

import GardenLayout from './GardenLayout';

vi.mock('./PlantSomethingModal', () => ({
  default: ({onCreated}) => (
    <div role="dialog" aria-label="Plant something">
      <button type="button" onClick={() => onCreated({}, {name: 'Kale'})}>Plant</button>
    </div>
  ),
}));

const kale = {id: 2, crop_name: 'Kale', icon_url: '/kale.png', icon_key: 'kale', url: '/plantings/kale', default_diameter: 1, planted_at: '2025-03-03', plants: [{id: 21, bed_x: null, bed_y: null, diameter: null}]};
const tomato = {id: 1, crop_name: 'Tomato', icon_url: '/tomato.png', icon_key: 'tomato', url: '/plantings/tomato', default_diameter: 2, planted_at: '2025-03-03', plants: [{id: 11, bed_x: 5, bed_y: 5, diameter: null}]};

function stubFetch(data = {}) {
  const fetch = vi.fn(async () => ({ok: true, status: 200, json: async () => data}));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

function setup(props = {}) {
  return render(
      <GardenLayout
        garden={{id: 1, grid_columns: 10, grid_rows: 8, url: '/gardens/1'}}
        editable
        resizable
        plantable
        max_grid_size={50}
        max_diameter={10}
        save_url="/gardens/1/layout"
        layout_url="/gardens/1/layout.json"
        spade_icon_url="/spade.png"
        compost_icon_url="/compost.png"
        plantings={[tomato, kale]}
        feature_icon_urls={{}}
        {...props}
      />,
  );
}

// jsdom's drop event takes neither a pointer position nor a data transfer.
const drop = (target, payload, point = {clientX: 30, clientY: 40}) => {
  const event = createEvent.drop(target);
  Object.defineProperties(event, {
    dataTransfer: {value: {getData: () => payload}},
    clientX: {value: point.clientX},
    clientY: {value: point.clientY},
  });
  fireEvent(target, event);
};
const bed = (container) => container.querySelector('.garden-layout-grid');
const savedBody = (fetch) => JSON.parse(fetch.mock.calls[0][1].body);

describe('GardenLayout', () => {
  beforeEach(() => {
    vi.spyOn(Element.prototype, 'getBoundingClientRect').mockReturnValue({left: 0, top: 0, width: 100, height: 80, right: 100, bottom: 80, x: 0, y: 0});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('draws a cell for each square of the bed', () => {
    const {container} = setup();
    expect(container.querySelectorAll('.garden-layout-cell')).toHaveLength(80);
  });

  it('draws the plants on the bed', () => {
    setup();
    expect(screen.getByAltText('Tomato')).toBeInTheDocument();
  });

  it('keeps plants that are waiting off the bed', () => {
    setup();
    expect(screen.queryByAltText('Kale')).not.toBeInTheDocument();
  });

  it('lists every planting in the tray', () => {
    setup();
    expect(screen.getByText('Kale', {selector: '.garden-layout-chip-name'})).toBeInTheDocument();
  });

  it('counts the plants waiting', () => {
    const {container} = setup();
    expect(container.querySelector('.garden-layout-chip-count')).toHaveTextContent('1');
  });

  it('says when nothing is growing', () => {
    setup({plantings: []});
    expect(screen.getByText('Nothing is growing here yet.')).toBeInTheDocument();
  });

  it('keeps a plant wholly on the bed', () => {
    const {container} = setup({plantings: [{...tomato, plants: [{id: 11, bed_x: 0, bed_y: 0, diameter: null}]}]});
    expect(container.querySelector('.garden-layout-plant')).toHaveStyle({left: '10%'});
  });

  it('tells apart plantings of the same crop by when they were planted', () => {
    setup({plantings: [tomato, {...tomato, id: 3, planted_at: '2025-04-04'}]});
    expect(screen.getAllByText(/^·/, {selector: '.garden-layout-chip-when'})).toHaveLength(2);
  });

  describe('when not editable', () => {
    it('links each planting', () => {
      setup({editable: false});
      expect(screen.getByRole('link', {name: /Kale/})).toHaveAttribute('href', '/plantings/kale');
    });

    it('has no feature toolbar', () => {
      setup({editable: false});
      expect(screen.queryByRole('group', {name: /Garden features/})).not.toBeInTheDocument();
    });

    it('has nothing to drag', () => {
      const {container} = setup({editable: false});
      expect(container.querySelector('[draggable]')).toBeNull();
    });

    it('has no Clear bed button', () => {
      setup({editable: false});
      expect(screen.queryByRole('button', {name: 'Clear bed'})).not.toBeInTheDocument();
    });
  });

  describe('when dropping a crop from the tray onto the bed', () => {
    it('puts the waiting plant where it was dropped', async () => {
      const fetch = stubFetch({plantings: [], features: []});
      const {container} = setup();
      await act(async () => drop(bed(container), 'stack:2'));
      expect(savedBody(fetch).placements).toContainEqual({plant_id: 21, bed_x: 3, bed_y: 4, diameter: null});
    });

    it('makes a new plant when none is waiting', async () => {
      const fetch = stubFetch({plantings: [], features: []});
      const {container} = setup();
      await act(async () => drop(bed(container), 'stack:1'));
      expect(savedBody(fetch).placements).toContainEqual({planting_id: 1, bed_x: 3, bed_y: 4, diameter: null});
    });

    it('saves to the layout url', async () => {
      const fetch = stubFetch({plantings: [], features: []});
      const {container} = setup();
      await act(async () => drop(bed(container), 'stack:2'));
      expect(fetch).toHaveBeenCalledWith('/gardens/1/layout', expect.objectContaining({method: 'PATCH'}));
    });
  });

  describe('when the save is refused', () => {
    it('puts the bed back as it was', async () => {
      vi.stubGlobal('fetch', vi.fn(async () => ({ok: false, status: 422, json: async () => ({errors: {base: ['plants overlap']}})})));
      const {container} = setup();
      await act(async () => drop(bed(container), 'stack:2'));
      expect(screen.getByText('Plants overlap. The bed has been put back as it was.')).toBeInTheDocument();
    });
  });

  describe('when dropping a plant back on the tray', () => {
    it('lifts it off the bed', async () => {
      const fetch = stubFetch({plantings: [], features: []});
      const {container} = setup();
      await act(async () => drop(container.querySelector('.garden-layout-tray'), 'plant:plant-11'));
      expect(savedBody(fetch).placements).toEqual([]);
    });
  });

  describe('when composting a plant', () => {
    beforeEach(() => {
      vi.stubGlobal('matchMedia', () => ({matches: true}));
    });

    it('tells the server which plant to delete', async () => {
      const fetch = stubFetch({plantings: [], features: []});
      setup();
      await act(async () => drop(screen.getByText('Compost bin').closest('.garden-layout-compost'), 'plant:plant-11'));
      expect(savedBody(fetch).composted).toEqual([11]);
    });

    it('says what was composted', async () => {
      stubFetch({plantings: [], features: []});
      setup();
      await act(async () => drop(screen.getByText('Compost bin').closest('.garden-layout-compost'), 'plant:plant-11'));
      expect(screen.getByText('Composted a Tomato.')).toBeInTheDocument();
    });

    it('will not compost a crop with every plant on the bed', async () => {
      stubFetch({plantings: [], features: []});
      setup();
      await act(async () => drop(screen.getByText('Compost bin').closest('.garden-layout-compost'), 'stack:1'));
      expect(screen.getByText(/Every Tomato is on the bed/)).toBeInTheDocument();
    });
  });

  describe('when clearing the bed', () => {
    it('asks first', async () => {
      const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false);
      setup();
      await userEvent.click(screen.getByRole('button', {name: 'Clear bed'}));
      expect(confirm).toHaveBeenCalledWith(expect.stringContaining('Take all 1 plants off the bed?'));
    });

    it('leaves everything if you say no', async () => {
      vi.spyOn(window, 'confirm').mockReturnValue(false);
      const fetch = stubFetch();
      setup();
      await userEvent.click(screen.getByRole('button', {name: 'Clear bed'}));
      expect(fetch).not.toHaveBeenCalled();
    });

    it('takes every plant off if you say yes', async () => {
      vi.spyOn(window, 'confirm').mockReturnValue(true);
      const fetch = stubFetch({plantings: [], features: []});
      setup();
      await userEvent.click(screen.getByRole('button', {name: 'Clear bed'}));
      expect(savedBody(fetch).placements).toEqual([]);
    });
  });

  describe('with features', () => {
    it('adds a stepping stone dropped on the bed', async () => {
      const fetch = stubFetch({plantings: [], features: []});
      const {container} = setup();
      await act(async () => drop(bed(container), 'new-feature:stone'));
      expect(savedBody(fetch).features).toEqual([expect.objectContaining({kind: 'stone', x: 3, y: 4})]);
    });

    it('adds a label with the text asked for', async () => {
      vi.spyOn(window, 'prompt').mockReturnValue('Basil row');
      const fetch = stubFetch({plantings: [], features: []});
      const {container} = setup();
      await act(async () => drop(bed(container), 'new-feature:label'));
      expect(savedBody(fetch).features[0]).toMatchObject({kind: 'label', text: 'Basil row'});
    });

    it('adds no label when none is typed', async () => {
      vi.spyOn(window, 'prompt').mockReturnValue(null);
      const fetch = stubFetch();
      const {container} = setup();
      await act(async () => drop(bed(container), 'new-feature:label'));
      expect(fetch).not.toHaveBeenCalled();
    });

    it('draws a line two cells long', async () => {
      const fetch = stubFetch({plantings: [], features: []});
      const {container} = setup();
      await act(async () => drop(bed(container), 'new-feature:fence'));
      expect(savedBody(fetch).features[0]).toMatchObject({kind: 'fence', x: 2, x2: 4, y: 4, y2: 4});
    });

    it('draws the labels it is given', () => {
      setup({features: [{id: 'f1', kind: 'label', x: 2, y: 2, text: 'Herbs'}]});
      expect(screen.getByText('Herbs')).toBeInTheDocument();
    });

    it('moves a feature dropped elsewhere', async () => {
      const fetch = stubFetch({plantings: [], features: []});
      const {container} = setup({features: [{id: 'f1', kind: 'label', x: 2, y: 2, text: 'Herbs'}]});
      await act(async () => drop(bed(container), 'feature:f1', {clientX: 60, clientY: 40}));
      expect(savedBody(fetch).features).toEqual([expect.objectContaining({id: 'f1', x: 6, y: 4})]);
    });

    it('renames a label on double click', async () => {
      vi.spyOn(window, 'prompt').mockReturnValue('Salad');
      const fetch = stubFetch({plantings: [], features: []});
      setup({features: [{id: 'f1', kind: 'label', x: 2, y: 2, text: 'Herbs'}]});
      await act(async () => { fireEvent.doubleClick(screen.getByText('Herbs')); });
      expect(savedBody(fetch).features[0].text).toBe('Salad');
    });

    it('takes a feature off the bed when it is dropped in the compost', async () => {
      vi.stubGlobal('matchMedia', () => ({matches: true}));
      const fetch = stubFetch({plantings: [], features: []});
      setup({features: [{id: 'f1', kind: 'label', x: 2, y: 2, text: 'Herbs'}]});
      await act(async () => drop(screen.getByText('Compost bin').closest('.garden-layout-compost'), 'feature:f1'));
      expect(savedBody(fetch).features).toEqual([]);
    });
  });

  describe('when resizable', () => {
    beforeEach(() => {
      vi.useFakeTimers({shouldAdvanceTime: true});
    });

    it('redraws the bed as the size is typed', () => {
      stubFetch();
      const {container} = setup();
      fireEvent.change(screen.getByLabelText('Columns'), {target: {value: '12'}});
      expect(container.querySelectorAll('.garden-layout-cell')).toHaveLength(96);
    });

    it('saves the size once typing pauses', async () => {
      const fetch = stubFetch();
      setup();
      fireEvent.change(screen.getByLabelText('Columns'), {target: {value: '12'}});
      await act(async () => { vi.advanceTimersByTime(700); });
      expect(fetch).toHaveBeenCalledWith('/gardens/1', expect.objectContaining({body: JSON.stringify({garden: {grid_columns: 12, grid_rows: 8}})}));
    });

    it('refuses a bed too small for what is on it', () => {
      stubFetch();
      setup();
      fireEvent.change(screen.getByLabelText('Columns'), {target: {value: '3'}});
      expect(screen.getByText(/The bed can't be that small/)).toBeInTheDocument();
    });

    it('ignores a size that is too big', () => {
      const {container} = setup();
      fireEvent.change(screen.getByLabelText('Columns'), {target: {value: '51'}});
      expect(container.querySelectorAll('.garden-layout-cell')).toHaveLength(80);
    });

    it('puts the size back when it cannot be saved', async () => {
      vi.stubGlobal('fetch', vi.fn(async () => ({ok: false, status: 422, json: async () => ({errors: {grid_columns: ['is too wide']}})})));
      const {container} = setup();
      fireEvent.change(screen.getByLabelText('Columns'), {target: {value: '12'}});
      await act(async () => { vi.advanceTimersByTime(700); });
      expect(container.querySelectorAll('.garden-layout-cell')).toHaveLength(80);
    });
  });

  describe('when not resizable', () => {
    it('has no size boxes', () => {
      setup({resizable: false});
      expect(screen.queryByLabelText('Columns')).not.toBeInTheDocument();
    });
  });

  describe('when planting something new', () => {
    it('opens the plant dialog', async () => {
      setup();
      await userEvent.click(screen.getByRole('button', {name: /Add a planting/}));
      expect(screen.getByRole('dialog', {name: 'Plant something'})).toBeInTheDocument();
    });

    it('refreshes the layout and says what to do next', async () => {
      stubFetch({plantings: [tomato, kale], features: []});
      setup();
      await userEvent.click(screen.getByRole('button', {name: /Add a planting/}));
      await userEvent.click(screen.getByRole('button', {name: 'Plant'}));
      expect(await screen.findByText('Planted Kale. Drag it onto the bed.')).toBeInTheDocument();
    });
  });

  describe('when not plantable', () => {
    it('has no Add a planting button', () => {
      setup({plantable: false});
      expect(screen.queryByRole('button', {name: /Add a planting/})).not.toBeInTheDocument();
    });
  });
});
