import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it} from 'vitest';

import ApiTokenCopy from './ApiTokenCopy';

describe('ApiTokenCopy', () => {
  const show = () => render(<ApiTokenCopy token="secret-token-value" copyLabel="Copy" copiedLabel="Copied" />);

  it('does not show the token', () => {
    show();
    expect(screen.queryByText('secret-token-value')).not.toBeInTheDocument();
  });

  it('copies the token', async () => {
    const user = userEvent.setup();
    show();
    await user.click(screen.getByRole('button', {name: 'Copy'}));
    expect(await navigator.clipboard.readText()).toBe('secret-token-value');
  });

  it('says when it has copied', async () => {
    const user = userEvent.setup();
    show();
    await user.click(screen.getByRole('button', {name: 'Copy'}));
    expect(screen.getByRole('button', {name: 'Copied'})).toBeInTheDocument();
  });
});
