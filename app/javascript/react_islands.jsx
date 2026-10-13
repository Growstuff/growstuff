// Entry point for the React "islands": small React components mounted into
// server-rendered pages. Rails renders an empty element with
// data-react-component="Name" and data-props='{...}' (see the react_component
// helper); this finds each one and mounts the matching component.
//
// To add a component: create it in ./components and register it below.
import React from 'react';
import {createRoot} from 'react-dom/client';

import GardenCards from './components/GardenCards';
import GardenLayout from './components/GardenLayout';
import GrowingTable from './components/GrowingTable';
import HarvestChart from './components/HarvestChart';
import LocationPicker from './components/LocationPicker';
import PhotoDialog from './components/PhotoDialog';
import PhotoPicker from './components/PhotoPicker';
import PlantPicker from './components/PlantPicker';
import PlantingPicker from './components/PlantingPicker';
import PlantingActions from './components/PlantingActions';
import PlantingRating from './components/PlantingRating';

const components = {GardenCards, GardenLayout, GrowingTable, HarvestChart, LocationPicker, PhotoDialog, PhotoPicker, PlantPicker, PlantingPicker, PlantingActions, PlantingRating};

function mountIslands() {
  document.querySelectorAll('[data-react-component]').forEach((element) => {
    const name = element.dataset.reactComponent;
    const Component = components[name];
    if (!Component) {
      console.error(`No React component registered as "${name}"`);
      return;
    }
    const props = JSON.parse(element.dataset.props || '{}');
    createRoot(element).render(<Component {...props} />);
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', mountIslands);
} else {
  mountIslands();
}
