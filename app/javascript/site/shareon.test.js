import { beforeEach, describe, expect, it } from 'vitest';
import { init } from './shareon';

describe('shareon', () => {
  beforeEach(() => {
    document.body.innerHTML = '';
  });

  it('populates share links when .shareon container is present', () => {
    document.body.innerHTML = `
      <div class="shareon">
        <a class="bluesky"></a>
        <a class="fediverse"></a>
        <a class="mastodon"></a>
        <a class="telegram"></a>
        <a class="copy-url"></a>
        <a class="email"></a>
        <a class="print"></a>
        <a class="web-share"></a>
      </div>
    `;

    init();

    const blueskyLink = document.querySelector('a.bluesky');
    expect(blueskyLink.getAttribute('href')).toContain('bsky.app');

    const mastodonLink = document.querySelector('a.mastodon');
    expect(mastodonLink.getAttribute('href')).toContain('toot.kytta.dev');

    const emailLink = document.querySelector('a.email');
    expect(emailLink.getAttribute('href')).toContain('mailto:');
  });

  it('does nothing if .shareon container is not present', () => {
    document.body.innerHTML = '<div class="other"></div>';

    expect(() => init()).not.toThrow();
  });
});
