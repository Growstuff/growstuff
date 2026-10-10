// A plain left click, as opposed to ctrl/cmd/shift/middle click, which should still open the link normally.
export function isPlainClick(event) {
  return event.button === 0 && !(event.metaKey || event.ctrlKey || event.shiftKey || event.altKey);
}
