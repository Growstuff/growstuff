import React from 'react';

import {selectPlantingAction} from '../plantingActions';
import ActionsMenu from './ActionsMenu';
import CropChip from './CropChip';

// A planting's crop chip, which is also its menu: click it for view, edit,
// harvest and the rest, the same for annuals and perennials. Someone who can't
// change the planting has no menu, so for them it stays a plain link to it.
export default function PlantingChip({planting, defaultIconUrl, highlighted, handlers}) {
  const {id, url, crop, label = crop.name, actions} = planting;

  if (!actions || actions.length === 0) {
    return <CropChip url={url} crop={crop} label={label} defaultIconUrl={defaultIconUrl} highlighted={highlighted} />;
  }

  return (
    <ActionsMenu
      id={`planting-${id}`}
      actions={actions}
      href={url}
      label={(
        <>
          <img className="crop-icon" src={crop.icon_url || defaultIconUrl} alt="" />
          <span className="crop-chip-name" title={label}>{label}</span>
        </>
      )}
      ariaLabel={`Actions for ${label}`}
      className={`chip crop-chip chip-menu-toggle dropdown-toggle${highlighted ? ' planting-just-added' : ''}`}
      menuClassName="dropdown-menu-start planting-menu"
      onSelect={selectPlantingAction(planting, handlers)}
    />
  );
}
