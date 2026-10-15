// Mounting React "islands": small React components in server-rendered pages.
// Rails renders an element with data-react-component="Name" and
// data-props='{...}' (see the react_component helper); mountIslands finds each
// one under `root` and mounts the matching component.
//
// A component that puts server-rendered HTML on the page (the seed library
// swaps in new results) calls mountIslands on it, and unmountIslands before it
// replaces it.
import React from 'react';
import {createRoot} from 'react-dom/client';

const components = {};
const roots = new Map(); // element => React root

export function registerIslands(registry) {
  Object.assign(components, registry);
}

export function mountIslands(root = document) {
  root.querySelectorAll('[data-react-component]').forEach((element) => {
    if (roots.has(element)) return;

    const name = element.dataset.reactComponent;
    const Component = components[name];
    if (!Component) {
      console.error(`No React component registered as "${name}"`);
      return;
    }
    const props = JSON.parse(element.dataset.props || '{}');
    const reactRoot = createRoot(element);
    roots.set(element, reactRoot);
    reactRoot.render(<Component {...props} />);
  });
}

export function unmountIslands(root) {
  root.querySelectorAll('[data-react-component]').forEach((element) => {
    const reactRoot = roots.get(element);
    if (!reactRoot) return;
    reactRoot.unmount();
    roots.delete(element);
  });
}
