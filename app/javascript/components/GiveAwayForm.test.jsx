import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {afterEach, describe, expect, it, vi} from 'vitest';

import GiveAwayForm from './GiveAwayForm';

const labels = {
  title: 'Give away seedlings', close: 'Close', cancel: 'Cancel', which: 'Which seedlings?', what_happened: 'What\'s happened to %{these}?',
  it: 'it', them: 'them', one_fewer: 'One fewer', one_more: 'One more', of_total: 'of %{total}', quantity_group: 'How many %{name}',
  stay: {one: '1 will stay', other: '%{count} will stay'}, given_title: 'Given to someone', given_hint: 'hint',
  offered_title: 'Put on my stall', offered_hint: 'hint', offered_detail: 'On offer.', help_title: 'Not sure',
  help_leaving: 'Leaving.', help_given_lead: 'a', help_given_rest: 'b', help_offered_lead: 'c', help_offered_rest: 'd',
  help_nothing_deleted: 'Nothing deleted.', who_has: 'Who has them?', search_placeholder: 'Search', suggestions_hint: 'Neighbours',
  matching_hint: 'Matching', no_match: 'No one called %{query}.', not_on_growstuff: 'Not on Growstuff', change: 'Change',
  their_name: 'Their name', required: '(required)', name_hint: 'hint', signin_heading: 'How they sign in', recommended: 'Recommended',
  signin_text: 'text', how_signin: 'How can they sign in?', email: 'Email', fediverse: 'Fediverse', bluesky: 'Bluesky',
  email_label: 'Their email address', mastodon_label: 'Their Fediverse handle', bluesky_label: 'Their Bluesky handle',
  email_placeholder: 'a@b.c', mastodon_placeholder: '@a@b.c', bluesky_placeholder: 'a.bsky.social', tell_them: 'Tell them: %{what}',
  email_what: 'email address', handle_what: 'handle', on_growstuff_after_all: 'On Growstuff after all', given_on: 'Given on',
  given_on_hint: 'hint', privacy_guest: 'Only you can see.', privacy_member: '%{name} will see these.',
  privacy_member_unnamed: 'They will see these.', submit_given: 'Record as given away', submit_offered: 'Put on my stall',
  on_stall: 'On your stall', none_left: 'None',
};
const seedlings = [
  {id: 1, label: 'Cucumber seedlings', detail: 'sown 3 Oct', total: 6},
  {id: 2, label: 'Cabbage seedlings', detail: 'sown 20 Sep', total: 1},
];
const sam = {id: 9, name: 'SamOkafor', place: 'Miramar'};

function setup(props = {}) {
  return render(
    <GiveAwayForm action="/stall/plantings" csrf="tok" cancelUrl="/stall" recipientsUrl="/stall/recipients" today="2026-11-15"
                  labels={labels} seedlings={seedlings} suggestions={[sam]} {...props} />,
  );
}

afterEach(() => vi.restoreAllMocks());

describe('GiveAwayForm', () => {
  it('has no submit button until a path is chosen', () => {
    setup({selected: {1: null}});
    expect(screen.queryByRole('button', {name: 'Put on my stall'})).not.toBeInTheDocument();
  });

  it('can put ticked seedlings on the stall without asking anything else', async () => {
    setup({selected: {1: null}});
    await userEvent.click(screen.getByRole('radio', {name: /Put on my stall/}));
    expect(screen.getByRole('button', {name: 'Put on my stall'})).toBeEnabled();
  });

  it('does not ask who has them for the stall', async () => {
    setup({selected: {1: null}});
    await userEvent.click(screen.getByRole('radio', {name: /Put on my stall/}));
    expect(screen.queryByLabelText('Who has them?')).not.toBeInTheDocument();
  });

  it('cannot submit with nothing ticked', async () => {
    setup({status: 'offered'});
    expect(screen.getByRole('button', {name: 'Put on my stall'})).toBeDisabled();
  });

  it('asks who has them when given', () => {
    setup({selected: {1: null}, status: 'given'});
    expect(screen.getByLabelText('Who has them?')).toBeInTheDocument();
  });

  it('cannot submit a gift until someone is picked', () => {
    setup({selected: {1: null}, status: 'given'});
    expect(screen.getByRole('button', {name: 'Record as given away'})).toBeDisabled();
  });

  it('submits a picked member', async () => {
    setup({selected: {1: null}, status: 'given'});
    await userEvent.click(screen.getByRole('button', {name: /SamOkafor/}));
    expect(screen.getByRole('button', {name: 'Record as given away'})).toBeEnabled();
  });

  it('sends the picked member\'s id', async () => {
    const {container} = setup({selected: {1: null}, status: 'given'});
    await userEvent.click(screen.getByRole('button', {name: /SamOkafor/}));
    expect(container.querySelector('input[name="recipient_member_id"]').value).toBe('9');
  });

  it('records a name for someone not on Growstuff', async () => {
    setup({selected: {1: null}, status: 'given'});
    await userEvent.click(screen.getByRole('button', {name: 'Not on Growstuff'}));
    await userEvent.type(screen.getByLabelText(/Their name/), 'Sam from the garden');
    expect(screen.getByRole('button', {name: 'Record as given away'})).toBeEnabled();
  });

  it('asks how they sign in for someone not on Growstuff, but does not need it', async () => {
    setup({selected: {1: null}, status: 'given'});
    await userEvent.click(screen.getByRole('button', {name: 'Not on Growstuff'}));
    expect(screen.getByLabelText('Their email address')).not.toBeRequired();
  });

  it('changes what it asks for to match how they sign in', async () => {
    setup({selected: {1: null}, status: 'given'});
    await userEvent.click(screen.getByRole('button', {name: 'Not on Growstuff'}));
    await userEvent.click(screen.getByRole('radio', {name: /Fediverse/}));
    expect(screen.getByLabelText('Their Fediverse handle')).toBeInTheDocument();
  });

  it('gives part of a batch', async () => {
    const {container} = setup({selected: {1: null}, status: 'offered'});
    await userEvent.click(screen.getByRole('button', {name: 'One fewer'}));
    expect(container.querySelector('input[name="quantities[1]"]').value).toBe('5');
  });

  it('says how many stay in the nursery', async () => {
    setup({selected: {1: null}, status: 'offered'});
    await userEvent.click(screen.getByRole('button', {name: 'One fewer'}));
    expect(screen.getByText('1 will stay')).toBeInTheDocument();
  });

  it('searches Growstuff by name', async () => {
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValue({ok: true, status: 200, json: async () => [{id: 5, name: 'Priya', place: null}]});
    setup({selected: {1: null}, status: 'given'});
    await userEvent.type(screen.getByLabelText('Who has them?'), 'pri');
    await waitFor(() => expect(screen.getByRole('button', {name: /Priya/})).toBeInTheDocument());
    expect(fetchMock).toHaveBeenCalledWith('/stall/recipients?q=pri', expect.anything());
  });

  it('shows the help without a way to submit', async () => {
    setup({selected: {1: null}});
    await userEvent.click(screen.getByRole('radio', {name: /Not sure/}));
    expect(screen.getByText('Nothing deleted.')).toBeInTheDocument();
  });

  it('shows what the server said was wrong', () => {
    setup({errors: ['Say who has them']});
    expect(screen.getByRole('alert')).toHaveTextContent('Say who has them');
  });
});
