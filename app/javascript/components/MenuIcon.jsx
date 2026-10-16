import React from 'react';

import ICONS from '../menuIcons.json';

// An action's `key` is not always the icon's name.
const ALIASES = {photo: 'add_photo', plan: 'activity', deactivate: 'archive', activate: 'planting'};

// The green line icon of an actions menu item. The drawings are shared with the
// server-rendered menus (see MENU_ICONS in app/helpers/icons_helper.rb).
export default function MenuIcon({name}) {
  const paths = ICONS[ALIASES[name] || name];
  if (!paths) return null;

  return (
    <svg className="menu-icon" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor"
         strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"
         dangerouslySetInnerHTML={{__html: paths}} />
  );
}
