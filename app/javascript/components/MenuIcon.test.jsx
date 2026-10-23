import {render} from '@testing-library/react';
import {describe, expect, it} from 'vitest';

import ICONS from '../menuIcons.json';
import MenuIcon from './MenuIcon';

const drawnElements = (markup) => markup.match(/<(path|circle|rect|line|polyline|polygon|ellipse)\b/g).length;

describe('MenuIcon', () => {
  it('draws the named icon', () => {
    const {container} = render(<MenuIcon name="garden" />);
    expect(container.querySelector('svg').children).toHaveLength(drawnElements(ICONS.garden));
  });

  it('hides the icon from assistive technology', () => {
    const {container} = render(<MenuIcon name="garden" />);
    expect(container.querySelector('svg')).toHaveAttribute('aria-hidden', 'true');
  });

  describe('with a name that is an alias', () => {
    it('draws the icon it stands for', () => {
      const {container} = render(<MenuIcon name="photo" />);
      expect(container.querySelector('svg').children).toHaveLength(drawnElements(ICONS.add_photo));
    });
  });

  describe('with an unknown name', () => {
    it('draws nothing', () => {
      const {container} = render(<MenuIcon name="no-such-icon" />);
      expect(container).toBeEmptyDOMElement();
    });
  });
});
