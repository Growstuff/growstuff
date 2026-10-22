import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { initFlashMessages } from './flash_messages';

describe('initFlashMessages', () => {
  let flashContainer;
  let alertEl;

  beforeEach(() => {
    vi.useFakeTimers();

    document.body.innerHTML = `
      <div class="flash-messages">
        <div class="alert alert-success alert-dismissible fade show" role="alert">
          <button class="btn-close" type="button" aria-label="Close"></button>
          <span>Settings saved!</span>
          <input type="text" id="alert-input" />
        </div>
      </div>
      <main>
        <button id="outside-btn">Outside</button>
        <input type="text" id="outside-input" />
      </main>
    `;

    flashContainer = document.querySelector('.flash-messages');
    alertEl = document.querySelector('.alert');
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('does not dismiss flash messages automatically before user interaction', () => {
    initFlashMessages(3000);

    vi.advanceTimersByTime(5000);

    expect(document.querySelector('.alert')).not.toBeNull();
  });

  it('starts 3-second auto-dismiss on window scroll user interaction', () => {
    initFlashMessages(3000);

    window.dispatchEvent(new Event('scroll'));

    vi.advanceTimersByTime(2900);
    expect(document.querySelector('.alert')).not.toBeNull();

    vi.advanceTimersByTime(300);
    // After fallback animation timeout (150ms), element is removed if bootstrap JS object is absent
    vi.advanceTimersByTime(200);
    expect(document.querySelector('.alert')).toBeNull();
  });

  it('starts 3-second auto-dismiss on touchstart interaction', () => {
    initFlashMessages(3000);

    window.dispatchEvent(new Event('touchstart'));

    vi.advanceTimersByTime(3500);
    expect(document.querySelector('.alert')).toBeNull();
  });

  it('starts 3-second auto-dismiss on focusin outside the alert', () => {
    initFlashMessages(3000);

    const outsideInput = document.getElementById('outside-input');
    outsideInput.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));

    vi.advanceTimersByTime(3500);
    expect(document.querySelector('.alert')).toBeNull();
  });

  it('pauses auto-dismiss timer while mouse hovers over the alert and resumes when unhovered', () => {
    initFlashMessages(3000);

    // Trigger user interaction
    window.dispatchEvent(new Event('scroll'));

    vi.advanceTimersByTime(2000);

    // Hover over alert
    alertEl.dispatchEvent(new MouseEvent('mouseenter'));

    // Advance past original 3 second mark
    vi.advanceTimersByTime(2000);
    expect(document.querySelector('.alert')).not.toBeNull();

    // Mouse leaves alert
    alertEl.dispatchEvent(new MouseEvent('mouseleave'));

    // Advance 2.9 seconds: still there
    vi.advanceTimersByTime(2900);
    expect(document.querySelector('.alert')).not.toBeNull();

    // Advance another 300ms + fallback
    vi.advanceTimersByTime(300 + 200);
    expect(document.querySelector('.alert')).toBeNull();
  });

  it('pauses auto-dismiss timer while focus is inside the alert', () => {
    initFlashMessages(3000);

    // Trigger user interaction
    window.dispatchEvent(new Event('scroll'));

    vi.advanceTimersByTime(2000);

    // Focus on input inside alert
    const alertInput = document.getElementById('alert-input');
    alertEl.dispatchEvent(new FocusEvent('focusin', { bubbles: true, target: alertInput }));

    vi.advanceTimersByTime(3000);
    expect(document.querySelector('.alert')).not.toBeNull();

    // Focus moves outside alert
    const outsideBtn = document.getElementById('outside-btn');
    alertEl.dispatchEvent(new FocusEvent('focusout', { bubbles: true, relatedTarget: outsideBtn }));

    vi.advanceTimersByTime(3500);
    expect(document.querySelector('.alert')).toBeNull();
  });

  it('uses window.bootstrap.Alert when available', () => {
    const closeSpy = vi.fn(() => {
      alertEl.remove();
    });

    window.bootstrap = {
      Alert: {
        getOrCreateInstance: vi.fn(() => ({
          close: closeSpy,
        })),
      },
    };

    initFlashMessages(3000);

    window.dispatchEvent(new Event('scroll'));

    vi.advanceTimersByTime(3100);

    expect(window.bootstrap.Alert.getOrCreateInstance).toHaveBeenCalledWith(alertEl);
    expect(closeSpy).toHaveBeenCalled();
    delete window.bootstrap;
  });
});
