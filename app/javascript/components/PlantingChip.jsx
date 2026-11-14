import React from 'react';

import {selectPlantingAction} from '../plantingActions';
import ActionsMenu from './ActionsMenu';
import CropChip from './CropChip';

// A planting's crop chip, which is also its menu: click it for view, edit,
// harvest and the rest, the same for annuals and perennials. Someone who can't
// change the planting has no menu, so for them it stays a plain link to it.
export default function PlantingChip({planting, defaultIconUrl, highlighted, handlers}) {
  const {id, url, crop, variety, actions} = planting;
  const name = variety ? `${crop.name} (${variety})` : crop.name;

  if (!actions || actions.length === 0) {
    return <CropChip url={url} crop={crop} variety={variety} defaultIconUrl={defaultIconUrl} highlighted={highlighted} />;
  }

  return (
    <ActionsMenu
      id={`planting-${id}`}
      actions={actions}
      href={url}
      label={(
        <>
          <img className="crop-icon" src={crop.icon_url || defaultIconUrl} alt="" />
          <span className="crop-chip-name" title={name}>{name}</span>
        </>
      )}
      ariaLabel={`Actions for ${name}`}
      className={`chip crop-chip chip-menu-toggle dropdown-toggle${highlighted ? ' planting-just-added' : ''}`}
      menuClassName="dropdown-menu-start planting-menu"
      onSelect={selectPlantingAction(planting, handlers)}
    />
  );
}
