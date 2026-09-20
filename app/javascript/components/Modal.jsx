import React, {useEffect, useRef} from 'react';

const FOCUSABLE = 'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled])';

// A modal dialog using Bootstrap's modal styles, controlled by React (so it
// doesn't need Bootstrap's modal JavaScript). Focus moves into the dialog and
// is kept there, Escape and a click on the backdrop close it, and focus goes
// back to where it was when it closes.
export default function Modal({title, titleId, onClose, children}) {
  const contentRef = useRef(null);

  useEffect(() => {
    const previouslyFocused = document.activeElement;
    document.body.classList.add('modal-open');
    const first = contentRef.current.querySelector('input, select, textarea');
    (first || contentRef.current).focus();

    return () => {
      document.body.classList.remove('modal-open');
      if (previouslyFocused && previouslyFocused.focus) previouslyFocused.focus();
    };
  }, []);

  function onKeyDown(event) {
    if (event.key === 'Escape') {
      onClose();
    } else if (event.key === 'Tab') {
      const focusable = contentRef.current.querySelectorAll(FOCUSABLE);
      if (focusable.length === 0) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    }
  }

  return (
    <>
      <div
        className="modal fade show d-block"
        tabIndex="-1"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onKeyDown={onKeyDown}
        onMouseDown={(event) => event.target === event.currentTarget && onClose()}
      >
        <div className="modal-dialog modal-lg">
          <div className="modal-content" ref={contentRef} tabIndex="-1">
            <div className="modal-header">
              <h2 className="modal-title h5" id={titleId}>{title}</h2>
              <button type="button" className="btn-close" aria-label="Close" onClick={onClose} />
            </div>
            {children}
          </div>
        </div>
      </div>
      <div className="modal-backdrop fade show" />
    </>
  );
}
