export function initFlashMessages(delay = 2000) {
  const flashContainer = document.querySelector('.flash-messages');
  if (!flashContainer) return;

  const alerts = Array.from(flashContainer.querySelectorAll('.alert'));
  if (alerts.length === 0) return;

  alerts.forEach((alertEl) => setupAutoDismiss(alertEl, delay));
}

function setupAutoDismiss(alertEl, delay) {
  let timer = null;
  let interactionStarted = false;
  let isHoveredOrFocused = false;

  const startTimer = () => {
    if (timer) clearTimeout(timer);
    if (isHoveredOrFocused) return;

    timer = setTimeout(() => {
      dismissAlert(alertEl);
    }, delay);
  };

  const pauseTimer = () => {
    if (timer) {
      clearTimeout(timer);
      timer = null;
    }
  };

  const handleInteraction = (event) => {
    // Ignore interaction events originating inside the alert itself
    if (event.target && (event.target instanceof Node) && alertEl.contains(event.target)) return;

    if (!interactionStarted) {
      interactionStarted = true;
      detachInteractionListeners();
    }

    startTimer();
  };

  const interactionEvents = ['scroll', 'touchstart', 'mousedown', 'keydown', 'focusin'];

  const attachInteractionListeners = () => {
    interactionEvents.forEach((type) => {
      window.addEventListener(type, handleInteraction, { capture: true, passive: true });
    });
  };

  const detachInteractionListeners = () => {
    interactionEvents.forEach((type) => {
      window.removeEventListener(type, handleInteraction, { capture: true });
    });
  };

  // Pause on hover or focus within the alert
  const onMouseEnter = () => {
    isHoveredOrFocused = true;
    pauseTimer();
  };

  const onMouseLeave = () => {
    isHoveredOrFocused = false;
    if (interactionStarted) {
      startTimer();
    }
  };

  const onFocusIn = (e) => {
    if (alertEl.contains(e.target)) {
      isHoveredOrFocused = true;
      pauseTimer();
    }
  };

  const onFocusOut = (e) => {
    if (!alertEl.contains(e.relatedTarget)) {
      isHoveredOrFocused = false;
      if (interactionStarted) {
        startTimer();
      }
    }
  };

  alertEl.addEventListener('mouseenter', onMouseEnter);
  alertEl.addEventListener('mouseleave', onMouseLeave);
  alertEl.addEventListener('focusin', onFocusIn);
  alertEl.addEventListener('focusout', onFocusOut);

  // Clean up if alert is dismissed manually
  alertEl.addEventListener('closed.bs.alert', () => {
    pauseTimer();
    detachInteractionListeners();
  });

  attachInteractionListeners();
}

function dismissAlert(alertEl) {
  if (window.bootstrap && window.bootstrap.Alert) {
    const bsAlert = window.bootstrap.Alert.getOrCreateInstance(alertEl);
    if (bsAlert) {
      bsAlert.close();
      return;
    }
  }

  // Fallback if Bootstrap JS object is not loaded
  alertEl.classList.remove('show');
  setTimeout(() => {
    alertEl.remove();
  }, 150);
}
