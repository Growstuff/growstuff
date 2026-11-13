import {render, screen} from '@testing-library/react';
import {beforeEach, describe, expect, it, vi} from 'vitest';
import * as MastodonTimeline from '@idotj/mastodon-embed-timeline';
import MastodonPosts from './MastodonPosts';

vi.mock('@idotj/mastodon-embed-timeline', () => ({Init: vi.fn(function() {})}));

const labels = {load: 'Load posts', feed: 'Mastodon', empty: 'No matches', view: 'Browse tag'};

async function load() {
  render(<MastodonPosts hashtag="tomato" labels={labels} />);
  return MastodonTimeline.Init.mock.calls[0][0];
}

describe('MastodonPosts', () => {
  beforeEach(() => vi.clearAllMocks());

  it('initializes the widget on page load', () => {
    render(<MastodonPosts hashtag="tomato" labels={labels} />);
    expect(MastodonTimeline.Init).toHaveBeenCalledTimes(1);
  });

  it('requests the crop hashtag from the configured instance', async () => {
    expect(await load()).toMatchObject({hashtagName: 'tomato', instanceUrl: 'https://mastodon.social'});
  });

  it('only accepts gardening posts', async () => {
    const {onBeforePostRender} = await load();
    expect(onBeforePostRender({tags: [{name: 'Gardening'}]})).toBe(true);
    expect(onBeforePostRender({tags: [{name: 'cooking'}]})).toBe(false);
    expect(onBeforePostRender({})).toBe(false);
  });

  it('limits matching posts to five', async () => {
    const {onBeforePostRender} = await load();
    const post = {tags: [{name: 'gardening'}]};
    for (let i = 0; i < 5; i += 1) expect(onBeforePostRender(post)).toBe(true);
    expect(onBeforePostRender(post)).toBe(false);
  });

  it('provides the widget with an isolated feed container', async () => {
    const options = await load();
    expect(document.getElementById(options.mtContainerId)).toContainElement(screen.getByRole('feed'));
  });
});
