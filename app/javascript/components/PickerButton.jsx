import React from 'react';

// The button each of the home page's dialogs opens from. A sublabel makes it a
// two-line tile: the label in bold, the sublabel under it. An icon, as Font
// Awesome classes, goes before the label.
export default function PickerButton({label, sublabel, className, icon, onClick}) {
  return (
    <button type="button" className={className} onClick={onClick}>
      {icon && <><i className={icon} aria-hidden="true" />{' '}</>}
      {sublabel ? <><b>{label}</b>{sublabel}</> : label}
    </button>
  );
}
