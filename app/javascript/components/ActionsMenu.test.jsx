import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import ActionsMenu from './ActionsMenu';

const actions = [
  {key: 'edit', label: 'Edit', href: '/g/1/edit'},
  {key: 'delete', label: 'Delete', href: '/g/1', method: 'delete', confirm: 'Sure?', divider: true},
];

function setup(props = {}) {
  return render(<ActionsMenu id="g1" actions={actions} {...props} />);
}

describe('ActionsMenu', () => {
  it('has a toggle named Actions', () => {
    setup();
    expect(screen.getByRole('button', {name: 'Actions'})).toHaveAttribute('data-bs-toggle', 'dropdown');
  });

  it('uses the given label for the toggle', () => {
    setup({label: 'Menu'});
    expect(screen.getByRole('button', {name: 'Menu'})).toBeInTheDocument();
  });

  it('uses the aria label for the toggle', () => {
    setup({ariaLabel: 'Actions for Tomato'});
    expect(screen.getByRole('button', {name: 'Actions for Tomato'})).toBeInTheDocument();
  });

  it('links each action', () => {
    setup();
    expect(screen.getByRole('link', {name: 'Edit'})).toHaveAttribute('href', '/g/1/edit');
  });

  it('passes the method for jquery_ujs', () => {
    setup();
    expect(screen.getByRole('link', {name: 'Delete'})).toHaveAttribute('data-method', 'delete');
  });

  it('passes the confirmation for jquery_ujs', () => {
    setup();
    expect(screen.getByRole('link', {name: 'Delete'})).toHaveAttribute('data-confirm', 'Sure?');
  });

  it('shows delete in red', () => {
    setup();
    expect(screen.getByRole('link', {name: 'Delete'})).toHaveClass('text-danger');
  });

  it('puts a divider before an action that asks for one', () => {
    const {container} = setup();
    expect(container.querySelectorAll('.dropdown-divider')).toHaveLength(1);
  });

  it('tells onSelect which action was clicked', async () => {
    const onSelect = vi.fn();
    setup({onSelect});
    await userEvent.click(screen.getByRole('link', {name: 'Edit'}));
    expect(onSelect).toHaveBeenCalledWith(actions[0], expect.anything());
  });

  describe('when onSelect takes over the click', () => {
    it('keeps the click from reaching the page', async () => {
      const onPage = vi.fn();
      document.addEventListener('click', onPage);
      setup({onSelect: (action, event) => event.preventDefault()});
      await userEvent.click(screen.getByRole('link', {name: 'Edit'}));
      document.removeEventListener('click', onPage);
      expect(onPage).not.toHaveBeenCalled();
    });
  });

  describe('without actions', () => {
    it('draws nothing', () => {
      const {container} = setup({actions: []});
      expect(container).toBeEmptyDOMElement();
    });
  });
});
