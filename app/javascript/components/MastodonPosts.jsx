import React, {useEffect, useId, useRef} from 'react';
import * as MastodonTimeline from '@idotj/mastodon-embed-timeline';

export default function MastodonPosts({hashtag, labels}) {
  const id = `mastodon-${useId().replace(/[^a-zA-Z0-9-]/g, '')}`;
  const container = useRef(null);
  const loaded = useRef(false);

  useEffect(() => {
    if (loaded.current) return;
    loaded.current = true;
    // The widget owns this subtree; React must not reconcile its contents.
    const body = document.createElement('div');
    body.className = 'mt-body';
    body.setAttribute('role', 'feed');
    body.setAttribute('aria-label', labels.feed);
    body.dataset.empty = labels.empty;
    const spinner = document.createElement('div');
    spinner.className = 'mt-loading-spinner';
    spinner.setAttribute('aria-label', labels.loading);
    body.append(spinner);
    container.current.replaceChildren(body);
    let shown = 0;
    new MastodonTimeline.Init({
      mtContainerId: id,
      instanceUrl: 'https://mastodon.social',
      timelineType: 'hashtag',
      hashtagName: hashtag,
      maxNbPostFetch: '40',
      // Filtering happens after this limit. Inspect the whole batch.
      maxNbPostShow: '40',
      hideUnlisted: true,
      hideReblog: true,
      hideReplies: true,
      hideCounterBar: true,
      hidePreviewLink: true,
      disableCarousel: true,
      txtMaxLines: '',
      btnSeeMoreTxt: '',
      btnReloadTxt: '',
      btnShowMoreTxt: labels.showMore,
      btnShowLessTxt: labels.showLess,
      btnShowContentTxt: labels.showContent,
      btnPlayVideoTxt: labels.playVideo,
      onBeforePostRender: post => {
        if (shown >= 5 || !post.tags?.some(tag => tag.name.toLowerCase() === 'gardening')) return false;
        shown += 1;
        return true;
      },
    });
  }, [id, hashtag, labels]);

  return <div className="crop-mastodon">
    <p className="small text-muted">{labels.description}</p>
    <div id={id} ref={container} className="mt-container" />
    <p className="small mt-2">
      <a href={`https://mastodon.social/tags/${encodeURIComponent(hashtag)}`} target="_blank" rel="noopener noreferrer">{labels.view}</a>
    </p>
  </div>;
}
