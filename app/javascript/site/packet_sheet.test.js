import { beforeEach, describe, expect, it } from 'vitest';
import { initPacketSheet, setEditing, toggleZoom } from './packet_sheet';

describe('the packet sheet', () => {
  let sheet;

  beforeEach(() => {
    document.body.innerHTML = `
      <a id="menu-edit" href="/seeds/1/edit" data-packet-sheet-edit>Edit</a>
      <div data-packet-sheet>
        <button id="edit-all" type="button" data-packet-sheet-edit>Edit all</button>
        <button class="seed-packet-text-toggle" aria-expanded="false" type="button">Show</button>
        <form class="packet-sheet-form">
          <input name="seed[variety]">
          <button id="cancel" type="button" data-packet-sheet-cancel>Cancel</button>
        </form>
      </div>`;
    sheet = document.querySelector('[data-packet-sheet]');
    sheet.scrollIntoView = () => {};
  });

  describe('setEditing', () => {
    it('shows the form when editing', () => {
      setEditing(sheet, true);
      expect(sheet.classList).toContain('is-editing');
    });

    it('puts the cursor in the first field', () => {
      setEditing(sheet, true);
      expect(document.activeElement.name).toBe('seed[variety]');
    });

    it('opens the text, which is wanted beside the fields', () => {
      let opened = false;
      sheet.querySelector('.seed-packet-text-toggle').addEventListener('click', () => { opened = true; });
      setEditing(sheet, true);
      expect(opened).toBe(true);
    });

    it('leaves the text open once it is', () => {
      let clicks = 0;
      const toggle = sheet.querySelector('.seed-packet-text-toggle');
      toggle.setAttribute('aria-expanded', 'true');
      toggle.addEventListener('click', () => { clicks += 1; });
      setEditing(sheet, true);
      expect(clicks).toBe(0);
    });

    it('goes back to the list when not editing', () => {
      setEditing(sheet, true);
      setEditing(sheet, false);
      expect(sheet.classList).not.toContain('is-editing');
    });
  });

  describe('zooming a packet photo', () => {
    let link;
    let image;

    beforeEach(() => {
      document.body.insertAdjacentHTML('beforeend', `
        <div class="seed-packet-photos"><a href="/photos/1"><img src="fit.jpg" data-large="large.jpg"></a></div>`);
      link = document.querySelector('.seed-packet-photos a');
      image = link.querySelector('img');
    });

    it('shows the big copy, full size', () => {
      toggleZoom(link);
      expect(image.getAttribute('src')).toBe('large.jpg');
    });

    it('marks the photos as zoomed', () => {
      toggleZoom(link);
      expect(link.closest('.seed-packet-photos').classList).toContain('is-zoomed');
    });

    it('goes back to the one that fits', () => {
      toggleZoom(link);
      toggleZoom(link);
      expect(image.getAttribute('src')).toBe('fit.jpg');
    });

    it('falls back to the one that fits if the big one is not there', () => {
      toggleZoom(link);
      image.onerror();
      expect(image.getAttribute('src')).toBe('fit.jpg');
    });

    it('zooms on a click, instead of going to the photo\'s page', () => {
      initPacketSheet();
      const click = new MouseEvent('click', { bubbles: true, cancelable: true });
      link.dispatchEvent(click);
      expect(click.defaultPrevented).toBe(true);
    });

    it('leaves a click with the control key down alone, to open in a new tab', () => {
      initPacketSheet();
      const click = new MouseEvent('click', { bubbles: true, cancelable: true, ctrlKey: true });
      link.dispatchEvent(click);
      expect(click.defaultPrevented).toBe(false);
    });
  });

  describe('the buttons', () => {
    beforeEach(() => initPacketSheet());

    it('Edit all starts editing', () => {
      document.getElementById('edit-all').click();
      expect(sheet.classList).toContain('is-editing');
    });

    it('the menu\'s Edit starts editing, instead of going to the form\'s page', () => {
      const click = new MouseEvent('click', { bubbles: true, cancelable: true });
      document.getElementById('menu-edit').dispatchEvent(click);
      expect(click.defaultPrevented).toBe(true);
    });

    it('Cancel stops editing', () => {
      setEditing(sheet, true);
      document.getElementById('cancel').click();
      expect(sheet.classList).not.toContain('is-editing');
    });
  });
});
