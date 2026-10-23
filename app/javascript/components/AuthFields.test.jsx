import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import {AuthFooter, CheckField, FormErrors, TextField, fieldErrors} from './AuthFields';

describe('fieldErrors', () => {
  const data = {errors: {email: ['is invalid', 'is taken'], recaptcha: ['failed'], base: ['Try later']}};
  const result = fieldErrors(data, ['email']);

  it('groups messages for the named fields', () => {
    expect(result.byField).toEqual({email: ['is invalid', 'is taken']});
  });

  it('names the field in other messages', () => {
    expect(result.other).toContain('Recaptcha failed');
  });

  it('shows base messages as they are', () => {
    expect(result.other).toContain('Try later');
  });

  it('copes with no errors', () => {
    expect(fieldErrors(null, ['email'])).toEqual({byField: {}, other: []});
  });
});

describe('TextField', () => {
  it('labels the input', () => {
    render(<TextField id="e" label="Email" />);
    expect(screen.getByLabelText('Email')).toBeInTheDocument();
  });

  it('shows the hint', () => {
    render(<TextField id="e" label="Email" hint="We never spam" />);
    expect(screen.getByLabelText('Email')).toHaveAccessibleDescription('We never spam');
  });

  it('shows the errors', () => {
    render(<TextField id="e" label="Email" errors={['is invalid']} />);
    expect(screen.getByLabelText('Email')).toHaveAccessibleDescription('is invalid');
  });

  it('marks the input invalid when there are errors', () => {
    render(<TextField id="e" label="Email" errors={['is invalid']} />);
    expect(screen.getByLabelText('Email')).toBeInvalid();
  });

  it('is valid without errors', () => {
    render(<TextField id="e" label="Email" />);
    expect(screen.getByLabelText('Email')).not.toHaveAttribute('aria-invalid');
  });

  it('passes other props to the input', () => {
    render(<TextField id="e" label="Email" type="email" />);
    expect(screen.getByLabelText('Email')).toHaveAttribute('type', 'email');
  });
});

describe('CheckField', () => {
  it('is a labelled checkbox', () => {
    render(<CheckField id="c" label="Agree" />);
    expect(screen.getByRole('checkbox', {name: 'Agree'})).toBeInTheDocument();
  });

  it('shows the errors', () => {
    render(<CheckField id="c" label="Agree" errors={['must be accepted']} />);
    expect(screen.getByRole('checkbox')).toHaveAccessibleDescription('must be accepted');
  });
});

describe('FormErrors', () => {
  it('draws nothing without messages', () => {
    const {container} = render(<FormErrors messages={[]} />);
    expect(container).toBeEmptyDOMElement();
  });

  it('announces the messages as an alert', () => {
    render(<FormErrors messages={['Bad', 'Worse']} />);
    expect(screen.getByRole('alert')).toHaveTextContent('BadWorse');
  });
});

describe('AuthFooter', () => {
  const props = {label: 'Sign in', busyLabel: 'Signing in…', prompt: 'New here?', switchLabel: 'Join', switchHref: '/join', onSwitch: vi.fn()};

  it('has a submit button', () => {
    render(<AuthFooter busy={false} {...props} />);
    expect(screen.getByRole('button', {name: 'Sign in'})).toHaveAttribute('type', 'submit');
  });

  it('shows the busy label while busy', () => {
    render(<AuthFooter busy {...props} />);
    expect(screen.getByRole('button', {name: 'Signing in…'})).toBeDisabled();
  });

  it('keeps the other dialog\'s page as the link target', () => {
    render(<AuthFooter busy={false} {...props} />);
    expect(screen.getByRole('link', {name: 'Join'})).toHaveAttribute('href', '/join');
  });

  it('switches dialog instead of following the link', async () => {
    const onSwitch = vi.fn();
    render(<AuthFooter busy={false} {...props} onSwitch={onSwitch} />);
    await userEvent.click(screen.getByRole('link', {name: 'Join'}));
    expect(onSwitch).toHaveBeenCalledTimes(1);
  });
});
