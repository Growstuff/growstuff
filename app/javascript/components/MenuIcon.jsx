import React from 'react';

// The green line icons of the actions menus, keyed by the action's `key`. The
// same drawings as MENU_ICONS in app/helpers/icons_helper.rb, which the
// server-rendered menus use; keep the two in step.
const PATHS = {
  view: <><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z" /><circle cx="12" cy="12" r="3" /></>,
  edit: <><path d="M4 20l1-4L16 5l3 3L8 19z" /><path d="M14 7l3 3" /></>,
  photo: <><path d="M4 8h3l2-3h6l2 3h3v11H4z" /><circle cx="12" cy="13" r="3.5" /></>,
  harvest: <><path d="M3 10h18l-2 10H5z" /><path d="M8 10l3-6M16 10l-3-6" /></>,
  seeds: <path d="M12 3c4 3 6 7 6 10a6 6 0 0 1-12 0c0-3 2-7 6-10z" />,
  finish: <><circle cx="12" cy="12" r="8" /><path d="M8.5 12.5l2.5 2.5 4.5-5" /></>,
  transplant: <><path d="M4 12h14M13 7l5 5-5 5" /><path d="M4 20h16" /></>,
  plan: <><rect x="4" y="5" width="16" height="15" rx="2" /><path d="M4 10h16M9 3v4M15 3v4" /></>,
  deactivate: <><path d="M4 7h16v4H4z" /><path d="M6 11v9h12v-9" /><path d="M10 15h4" /></>,
  activate: <><path d="M12 21v-8" /><path d="M12 13c0-4-3-6-7-6 0 4 3 6 7 6z" /><path d="M12 15c0-3 2-5 6-5 0 3-2 5-6 5z" /></>,
  delete: <><path d="M4 7h16" /><path d="M9 7V4h6v3" /><path d="M6 7l1 13h10l1-13" /><path d="M10 11v6M14 11v6" /></>,
};

export default function MenuIcon({name}) {
  const paths = PATHS[name];
  if (!paths) return null;

  return (
    <svg className="menu-icon" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor"
         strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      {paths}
    </svg>
  );
}
