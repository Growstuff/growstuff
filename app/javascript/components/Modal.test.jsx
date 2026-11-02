import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import Modal from './Modal';

function setup(props = {}) {
  const onClose = vi.fn();
  render(
      <Modal title="Plant" titleId="t" onClose={onClose} {...props}>
        <input aria-label="Name" />
        <button type="button">Save</button>
      </Modal>,
  );
  return onClose;
}

describe('Modal', () => {
  it('is a dialog named by its title', () => {
    setup();
    expect(screen.getByRole('dialog', {name: 'Plant'})).toBeInTheDocument();
  });

  it('is modal', () => {
    setup();
    expect(screen.getByRole('dialog')).toHaveAttribute('aria-modal', 'true');
  });

  it('renders into the body', () => {
    setup();
    expect(screen.getByRole('dialog').parentElement).toBe(document.body);
  });

  it('focuses the first field', () => {
    setup();
    expect(screen.getByLabelText('Name')).toHaveFocus();
  });

  it('stops the page behind scrolling', () => {
    setup();
    expect(document.body).toHaveClass('modal-open');
  });

  it('closes with the close button', async () => {
    const onClose = setup();
    await userEvent.click(screen.getByRole('button', {name: 'Close'}));
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('closes on Escape', async () => {
    const onClose = setup();
    await userEvent.keyboard('{Escape}');
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('closes on a click on the backdrop', async () => {
    const onClose = setup();
    await userEvent.pointer({keys: '[MouseLeft]', target: screen.getByRole('dialog')});
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('stays open on a click inside the dialog', async () => {
    const onClose = setup();
    await userEvent.click(screen.getByRole('button', {name: 'Save'}));
    expect(onClose).not.toHaveBeenCalled();
  });

  it('keeps Tab inside, wrapping from the last control to the first', async () => {
    setup();
    screen.getByRole('button', {name: 'Save'}).focus();
    await userEvent.tab();
    expect(screen.getByRole('button', {name: 'Close'})).toHaveFocus();
  });

  it('keeps Shift+Tab inside, wrapping from the first control to the last', async () => {
    setup();
    screen.getByRole('button', {name: 'Close'}).focus();
    await userEvent.tab({shift: true});
    expect(screen.getByRole('button', {name: 'Save'})).toHaveFocus();
  });

  describe('when closed', () => {
    it('lets the page scroll again', () => {
      const {unmount} = render(<Modal title="x" titleId="x" onClose={vi.fn()}><p>hi</p></Modal>);
      unmount();
      expect(document.body).not.toHaveClass('modal-open');
    });

    it('gives focus back to where it was', () => {
      const opener = document.createElement('button');
      document.body.appendChild(opener);
      opener.focus();
      const {unmount} = render(<Modal title="x" titleId="x" onClose={vi.fn()}><p>hi</p></Modal>);
      unmount();
      expect(opener).toHaveFocus();
      opener.remove();
    });

    it('gives focus back to the offcanvas trigger when opened from a closed offcanvas', () => {
      const trigger = document.createElement('button');
      trigger.setAttribute('data-bs-target', '#test-offcanvas');
      document.body.appendChild(trigger);

      const offcanvas = document.createElement('div');
      offcanvas.id = 'test-offcanvas';
      offcanvas.className = 'offcanvas';
      const link = document.createElement('a');
      link.href = '#';
      offcanvas.appendChild(link);
      document.body.appendChild(offcanvas);

      link.focus();
      const {unmount} = render(<Modal title="x" titleId="x" onClose={vi.fn()}><p>hi</p></Modal>);
      unmount();

      expect(trigger).toHaveFocus();

      trigger.remove();
      offcanvas.remove();
    });
  });

  describe('when an offcanvas is open', () => {
    it('closes the open offcanvas on mount', () => {
      const hide = vi.fn();
      window.bootstrap = {
        Offcanvas: {
          getInstance: vi.fn(() => ({hide})),
          getOrCreateInstance: vi.fn(() => ({hide})),
        },
      };

      const offcanvas = document.createElement('div');
      offcanvas.id = 'quickAdd';
      offcanvas.className = 'offcanvas show';
      document.body.appendChild(offcanvas);

      render(<Modal title="x" titleId="x" onClose={vi.fn()}><p>hi</p></Modal>);

      expect(hide).toHaveBeenCalled();

      offcanvas.remove();
      delete window.bootstrap;
    });
  });

  describe('with a size', () => {
    it('uses it for the dialog', () => {
      setup({size: 'sm'});
      expect(screen.getByRole('dialog').firstChild).toHaveClass('modal-sm');
    });
  });
});
