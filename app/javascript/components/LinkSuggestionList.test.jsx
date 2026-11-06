import {render, screen} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {describe, expect, it, vi} from 'vitest';

import LinkSuggestionList from './LinkSuggestionList';

const items = [
  {group: 'Crops', kind: 'crop', label: 'Pumpkin'},
  {group: 'Crops', kind: 'crop', label: 'Pumpkin, Crown Prince'},
  {group: 'Members', kind: 'member', label: 'pumpkinfan'},
  {group: 'Yours', kind: 'planting', label: 'Pumpkin in Patch', slug: 'a-patch-pumpkin', detail: 'Planting'},
];
const rect = {left: 10, bottom: 20};

describe('LinkSuggestionList', () => {
  it('lists every match', () => {
    render(<LinkSuggestionList items={items} selected={0} rect={rect} onChoose={() => {}} />);
    expect(screen.getAllByRole('option')).toHaveLength(4);
  });

  it('says what each group is', () => {
    render(<LinkSuggestionList items={items} selected={0} rect={rect} onChoose={() => {}} />);
    expect(screen.getAllByText(/^(Crops|Members|Yours)$/)).toHaveLength(3);
  });

  it('marks the highlighted match', () => {
    render(<LinkSuggestionList items={items} selected={2} rect={rect} onChoose={() => {}} />);
    expect(screen.getByRole('option', {name: /pumpkinfan/})).toHaveAttribute('aria-selected', 'true');
  });

  it('chooses a match with the mouse', async () => {
    const onChoose = vi.fn();
    render(<LinkSuggestionList items={items} selected={0} rect={rect} onChoose={onChoose} />);
    await userEvent.click(screen.getByRole('option', {name: /Pumpkin in Patch/}));
    expect(onChoose).toHaveBeenCalledWith(items[3]);
  });

  it('draws nothing without matches', () => {
    const {container} = render(<LinkSuggestionList items={[]} selected={0} rect={rect} onChoose={() => {}} />);
    expect(container).toBeEmptyDOMElement();
  });
});
