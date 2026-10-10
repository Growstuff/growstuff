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

const components = {GardenCards, GardenLayout};

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
