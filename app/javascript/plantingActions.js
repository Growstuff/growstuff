import {isPlainClick} from './events';

// What a click on one of a planting's menu items does: if there is a dialog for
// that item (handlers is keyed by the action's key: edit, harvest, seeds, photo,
// finish) it opens it, over the list; anything else, and ctrl/cmd-click, follows
// the link as usual.
export function selectPlantingAction(planting, handlers) {
  return (action, event) => {
    const open = handlers[action.key];
    if (open && isPlainClick(event)) {
      event.preventDefault();
      open(planting, action);
    }
  };
}
